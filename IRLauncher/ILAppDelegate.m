//
//  ILAppDelegate.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILLog.h"
#import "ILMenuletView.h"
#import "ILVersionChecker.h"
#import "ILUtils.h"
#import "ILSignalsDirectorySearcher.h"
#import "IRSignals.h"
#import "IRKit.h"
#import "ILFileStore.h"
#import "ILMenuProgressView.h"
#import "ILConst.h"
#import "ILMenu.h"
#import "ILUSBWatcher.h"
#import "ILUSBConnectedPeripheral.h"
#import "ILQuicksilverExtension.h"
#import "ILSender.h"

const int kSignalTagOffset                             = 1000;
const int kPeripheralTagOffset                         = 100;
const int kUSBTagOffset                                = 200;
static NSString * const kIRKitAPIKey                   = @"E4D85D012E1B4735BC6F3EBCCCAE4100";
static NSString * const kILDistributedNotificationName = @"jp.maaash.IRLauncher.send";

#define kILUSBVendorIRKit     @0x1D50
#define kILUSBProductIRKit    @0x6085

#define kILUSBVendorArduino   @0x2341
#define kILUSBProductLeonardo @0x8036

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILMenu *menu;
@property (nonatomic, strong) IRSignals *signals;
@property (nonatomic, strong) IRPeripherals *peripherals;
@property (nonatomic, strong) NSMutableArray *usbConnectedPeripherals;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ILLOG_CURRENT_METHOD;

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    ILLOG( @"args: %@", args );
    NSString *lastArgument   = (args.count > 1) ? args.lastObject : nil;
    BOOL isDuplicateInstance = [[NSRunningApplication runningApplicationsWithBundleIdentifier: [[NSBundle mainBundle] bundleIdentifier]] count] > 1;
    if (lastArgument) {
        if (isDuplicateInstance) {
            ILLOG( @"found duplicate, send over to living app" );
            [self postDistributedNotificationToSendFileAtPath: lastArgument];
            [NSApp terminate: nil];
            return;
        }
        else {
            // do it by myself
            [self performSelector: @selector(postDistributedNotificationToSendFileAtPath:)
                       withObject: lastArgument
                       afterDelay: 0.1];
        }
    }
    [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                        selector: @selector(receivedDistributedNotification:)
                                                            name: nil
                                                          object: nil];

    __weak typeof(self) _self = self;
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];

    ILFileStore *store = [[ILFileStore alloc] init];
    [IRKit setPersistentStore: store];
    [IRKit startWithAPIKey: kIRKitAPIKey];

    self.menu                  = (ILMenu*)[ILUtils loadClassFromNib: [ILMenu class]];
    self.menu.checkboxDelegate = self;
    self.menu.menuDelegate     = self;
    [self.menu setQuicksilverIntegrationTitle: @"Quicksilver Integration"
                               alternateTitle: @"Quicksilver Integration (Installed)"
                                  buttonTitle: @"Install"
                         alternateButtonTitle: @"Uninstall"
                                       action:^(id sender, NSCellStateValue _) {
        ILLOG( @"sender: %@ value: %d", sender, _ );
        if ([[[ILQuicksilverExtension alloc] init] installed]) {
            [_self showConfirmToUninstall:^(NSInteger returnCode) {
                if (returnCode == NSAlertFirstButtonReturn) {
                    [[[ILQuicksilverExtension alloc] init] uninstall];
                    [_self.menu setQuicksilverIntegrationButtonState: [[[ILQuicksilverExtension alloc] init] installed]];
                }
            }];
        }
        else {
            [_self showConfirmToInstall:^(NSInteger returnCode) {
                if (returnCode == NSAlertFirstButtonReturn) {
                    [[[ILQuicksilverExtension alloc] init] install];
                    [_self.menu setQuicksilverIntegrationButtonState: [[[ILQuicksilverExtension alloc] init] installed]];
                    NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.blacktree.Quicksilver"];
                    if (quicksilvers.count) {
                        [_self showConfirmToRelaunchQuicksilver:^(NSInteger returnCode) {
                            NSRunningApplication *q = quicksilvers[ 0 ];
                            BOOL success = [q terminate];
                            if (!success) {
                                ILLOG( @"failed to terminate quicksilver" );
                            }
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.blacktree.Quicksilver"];
                                if (quicksilvers.count) {
                                    ILLOG( @"failed to terminate quicksilver" );
                                    return;
                                }
                                BOOL success = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier: @"com.blacktree.Quicksilver"
                                                                                                    options: NSWorkspaceLaunchDefault
                                                                             additionalEventParamDescriptor: NULL
                                                                                           launchIdentifier: NULL];
                                if (!success) {
                                    ILLOG( @"failed to launch quicksilver" );
                                }
                            });
                        }];
                    }
                }
            }];
        }
    }];
    [self.menu setQuicksilverIntegrationButtonState: [[[ILQuicksilverExtension alloc] init] installed]];

    [self.menu setStartAtLoginTitle: @"Start at Login"
                     alternateTitle: @"Start at Login"
                             action:^(id sender, NSCellStateValue value) {
        ILLOG( @"sender: %@ value: %d", sender, value );
        if (value) {
            // value: 1 : off -> on

        }
        else {
            // value: 0 : on -> off
        }
    }];
    [self.menu setStartAtLoginState: NSOnState];

    self.menuletView      = [[ILMenuletView alloc] initWithFrame: (NSRect){.size={thickness, thickness}}];
    self.menuletView.menu = self.menu;

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength: thickness];
    [self.item setView: self.menuletView];
    [self.item setHighlightMode: NO];

    self.menuletView.statusItem = self.item;

    self.signals = [[IRSignals alloc] init];

    [self.menu setSignalHeaderTitle: @"Signals (Searching...)" animating: YES];

    [ILSignalsDirectorySearcher findSignalsUnderDirectory: [NSURL fileURLWithPath: [ILFileStore signalsDirectory]]
                                               completion: ^(NSArray *foundSignals) {
        [_self.menu setSignalHeaderTitle: @"Signals" animating: NO];
        [foundSignals enumerateObjectsUsingBlock: ^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
            IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
            [_self.signals addSignalsObject: signal];

            NSUInteger index = [_self.signals indexOfSignal: signal];
            NSMenuItem *signalItem = [[NSMenuItem alloc] init];
            signalItem.title  = signal.name;
            signalItem.target = _self;
            signalItem.action = @selector(send:);
            signalItem.tag    = kSignalTagOffset + index;
            if (index < 10) {
                signalItem.keyEquivalent = [NSString stringWithFormat: @"%lu", (unsigned long)index];
            }
            [_self.menu addSignalMenuItem: signalItem];
        }];
        [self.menu setSignalHeaderTitle: @"Signals" animating: NO];
    }];

    [IRSearcher sharedInstance].delegate = self;

    [self.menu setUSBHeaderTitle: @"Connect IRKit via USB to update firmware" animating: NO];
    self.usbConnectedPeripherals = @[].mutableCopy;

    [[ILUSBWatcher sharedInstance] startWatchingUSB];
    [[NSNotificationCenter defaultCenter] addObserverForName: kILUSBWatcherNotificationAdded
                                                      object: nil
                                                       queue: NULL
                                                  usingBlock: ^(NSNotification *note) {
        NSDictionary *info = note.userInfo;

        if ( ([info[ kILUSBWatcherNotificationVendorIDKey ] isEqualToNumber: kILUSBVendorIRKit] &&
              [info[ kILUSBWatcherNotificationProductIDKey ] isEqualToNumber: kILUSBProductIRKit]) ||
             ([info [kILUSBWatcherNotificationVendorIDKey ] isEqualToNumber: kILUSBVendorArduino] &&
              [info[ kILUSBWatcherNotificationProductIDKey ] isEqualToNumber: kILUSBProductLeonardo]) ) {
            ILLOG( @"connected USB: %@", info );

            ILUSBConnectedPeripheral *peripheral = [[ILUSBConnectedPeripheral alloc] init];
            peripheral.dialinDevice = info[ kILUSBWatcherNotificationDialinDeviceKey ];
            peripheral.locationId = info[ kILUSBWatcherNotificationLocationIDKey ];
            [_self.usbConnectedPeripherals addObject: peripheral];

            NSUInteger index = [_self.usbConnectedPeripherals indexOfObject: peripheral];
            NSMenuItem *usbItem = [[NSMenuItem alloc] init];
            NSString *title = [NSString stringWithFormat: @"%@ (%@)"
                               , [ILUtils chompedString: info[ kILUSBWatcherNotificationDeviceNameKey ]]
                               , peripheral.dialinDevice];
            ILMenuButtonView *view = [ILUtils loadClassFromNib: [ILMenuButtonView class]];
            [view setTitle: title
                   alternateTitle: title
                      buttonTitle: @"Update Firmware"
             alternateButtonTitle: @"Update Firmware"
                           action:^(id sender, NSCellStateValue value) {
                ILLOG( @"will update %@", title );
            }];
            view.state = NSOffState;
            usbItem.view = view;
            usbItem.tag = kUSBTagOffset + index;
            [_self.menu addUSBMenuItem: usbItem];
            [_self.menu setUSBHeaderTitle: @"IRKits connected via USB" animating: NO];
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName: kILUSBWatcherNotificationRemoved
                                                      object: nil
                                                       queue: nil
                                                  usingBlock:^(NSNotification *note) {
        NSDictionary *info = note.userInfo;
        ILLOG( @"removed USB: %@", info );
        NSNumber *locationId = info[ kILUSBWatcherNotificationLocationIDKey ];
        ILUSBConnectedPeripheral *peripheral = (ILUSBConnectedPeripheral*)[ILUtils firstObjectOf: _self.usbConnectedPeripherals meetsBlock:^BOOL (id obj, NSUInteger idx) {
            ILUSBConnectedPeripheral *p = obj;
            if ([p.locationId isEqualToNumber: locationId]) {
                return YES;
            }
            return NO;
        }];
        if (!peripheral) {
            return;
        }
        NSUInteger index = [_self.usbConnectedPeripherals indexOfObject: peripheral];
        [_self.usbConnectedPeripherals removeObject: peripheral];
        [_self.menu removeUSBMenuItemAtIndex: index];
        if (_self.usbConnectedPeripherals.count == 0) {
            [_self.menu setUSBHeaderTitle: @"IRKits connected via USB (none found)" animating: NO];
        }
    }];
}

- (void) notifyUpdate:(NSString*)hostname newVersion:(NSString*)newVersion currentVersion:(NSString*)currentVersion {
    ILLOG( @"hostname: %@ newVersion: %@ currentVersion: %@", hostname, newVersion, currentVersion);

}

#pragma mark - NSDistributedNotification related

- (void)postDistributedNotificationToSendFileAtPath: (NSString*)path {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: kILDistributedNotificationName
                                                                   object: [[NSBundle mainBundle] bundleIdentifier]
                                                                 userInfo: @{ @"path": path }
                                                       deliverImmediately: YES];
}

- (void)receivedDistributedNotification:(NSNotification*)notification {
    // ILLOG( @"sender: %@", notification );
    if ([notification.name isEqualToString: kILDistributedNotificationName]) {
        NSString *path = notification.userInfo[ @"path" ];
        ILLOG( @"will send: %@", path );
        [[[ILSender alloc] init] sendFileAtPath: path completion:^(NSError *error) {
            ILLOG( @"error: %@", error );

            NSString *message;
            switch (error.code) {
            case IRLauncherErrorCodeInvalidFile:
                message = [NSString stringWithFormat: @"Failed to load file: %@", path];
                break;
            case IRLauncherErrorCodeUnsupported:
                message = @"Unsupported file format";
                break;
            default:
                message = [NSString stringWithFormat: @"Failed to send file: %@ with error: %@", path, error];
                break;
            }

            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle: @"OK"];
            [alert setMessageText: message];
            [alert setAlertStyle: NSWarningAlertStyle];
            [alert runModal];
        }];
    }
}

#pragma mark - Private confirm methods

- (void) showConfirmToInstall:(void (^)(NSInteger returnCode))callback {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"]; // right most : NSAlertFirstButtonReturn
    [alert addButtonWithTitle: @"Cancel"]; // 2nd to right : NSAlertSecondButtonReturn
    [alert setMessageText: @"Install Quicksilver Plugin?"];
    [alert setInformativeText: @"I will edit ~/Library/Application Support/Quicksilver/Catalog.plist and add ~/.irkit.d/signals into Quicksilver's search paths."];
    [alert setAlertStyle: NSWarningAlertStyle];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    NSInteger ret = [alert runModal];
    callback( ret );
}

- (void) showConfirmToUninstall:(void (^)(NSInteger returnCode))callback {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"];
    [alert addButtonWithTitle: @"Cancel"];
    [alert setMessageText: @"Uninstall Quicksilver Plugin?"];
    [alert setInformativeText: @"I will edit ~/Library/Application Support/Quicksilver/Catalog.plist and remove IRLauncher related entries from it."];
    [alert setAlertStyle: NSWarningAlertStyle];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    NSInteger ret = [alert runModal];
    callback( ret );
}

- (void) showConfirmToRelaunchQuicksilver:(void (^)(NSInteger returnCode))callback {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"];
    [alert addButtonWithTitle: @"Cancel"];
    [alert setMessageText: @"Relaunch Quicksilver?"];
    [alert setAlertStyle: NSWarningAlertStyle];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    NSInteger ret = [alert runModal];
    callback( ret );
}

#pragma mark - NSMenuItem actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger signalIndex = ((NSMenuItem*)sender).tag - kSignalTagOffset;
    IRSignal *signal       = (IRSignal*)[self.signals objectInSignalsAtIndex: signalIndex];
    [signal sendWithCompletion:^(NSError *error) {
        ILLOG( @"sent: %@", error );
    }];
}

- (IBAction) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;
}

- (IBAction) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
}

#pragma mark - ILMenuCheckboxViewDelegate

- (void) menuCheckboxView:(ILMenuCheckboxView *)view didTouchCheckbox:(id)sender newValue:(BOOL)onoff {
    ILLOG( @"value: %d", onoff );
}

#pragma mark - ILMenuDelegate

- (void) menuWillOpen:(ILMenu *)menu {
    ILLOG_CURRENT_METHOD;
    [[IRSearcher sharedInstance] startSearchingForTimeInterval: 5.];
}

- (void) menuDidClose:(ILMenu *)menu {
    ILLOG_CURRENT_METHOD;

    [[IRSearcher sharedInstance] stop];
}

#pragma mark - IRSearcherDelegate

- (void) searcherWillStartSearching:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;

    [_menu setPeripheralHeaderTitle: @"IRKits (Searching...)" animating: YES];
}

- (void) searcher:(IRSearcher *)searcher didResolveService:(NSNetService *)service {
    ILLOG( @"service: %@", service );

    IRPeripherals *peripherals = [IRKit sharedInstance].peripherals;

    NSString *name  = [service.hostName componentsSeparatedByString: @"."][ 0 ];
    IRPeripheral *p = [peripherals peripheralWithName: name];
    if (!p) {
        p = [peripherals registerPeripheralWithName: name];
        [peripherals save];
    }
    if (!p.deviceid) {
        [p getKeyWithCompletion:^{
            [peripherals save];
        }];
    }
}

- (void) searcherDidTimeout:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;
    [self.menu setPeripheralHeaderTitle: @"IRKits" animating: NO];
    [[IRSearcher sharedInstance] startSearchingAfterTimeInterval: 5. forTimeInterval: 5.];
}

@end
