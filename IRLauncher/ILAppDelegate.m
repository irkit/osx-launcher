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
#import "ILQuicksilverExtension.h"
#import "ILSender.h"
#import "NSMenuItem+StateAware.h"

const int kSignalTagOffset                             = 1000;
const int kPeripheralTagOffset                         = 100;
static NSString * const kIRKitAPIKey                   = @"E4D85D012E1B4735BC6F3EBCCCAE4100";
static NSString * const kILDistributedNotificationName = @"jp.maaash.IRLauncher.send";

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILMenu *menu;
@property (nonatomic, strong) IRSignals *signals;

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
    [IRKit setPersistentStore: store]; // call before `startWithAPIKey`
    [IRKit startWithAPIKey: kIRKitAPIKey];

    self.menu              = (ILMenu*)[ILUtils loadClassFromNib: [ILMenu class]];
    self.menu.menuDelegate = self;

    self.menuletView      = [[ILMenuletView alloc] initWithFrame: (NSRect){.size={thickness, thickness}}];
    self.menuletView.menu = self.menu;

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: thickness];
    [self.statusItem setView: self.menuletView];
    [self.statusItem setHighlightMode: NO];

    self.menuletView.statusItem = self.statusItem;

    // setup menu items
    // signals

    self.signals = [[IRSignals alloc] init];

    [self.menu setSignalHeaderTitle: @"Signals (Searching...)" animating: YES];

    [ILSignalsDirectorySearcher findSignalsUnderDirectory: [NSURL fileURLWithPath: [ILFileStore signalsDirectory]]
                                               completion: ^(NSArray *foundSignals) {
        [_self.menu setSignalHeaderTitle: @"Signals" animating: NO];
        [foundSignals enumerateObjectsUsingBlock: ^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
            IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
            if (!signal.peripheral) {
                // skip signals without hostname
                // TODO somehow indicate that we skipped?
                return;
            }

            [_self.signals addSignalsObject: signal];
            NSUInteger index = [_self.signals indexOfSignal: signal];
            NSMenuItem *item = [_self menuItemForSignal: signal atIndex: index];
            [_self.menu addSignalMenuItem: item];
        }];
        [self.menu setSignalHeaderTitle: @"Signals" animating: NO];
    }];

    // peripherals

    NSArray *peripherals = [IRKit sharedInstance].peripherals.peripherals;
    [peripherals enumerateObjectsUsingBlock:^(IRPeripheral *peripheral, NSUInteger idx, BOOL *stop) {
        NSMenuItem *item = [_self menuItemForPeripheral: peripheral atIndex: idx];
        [_self.menu addPeripheralMenuItem: item];
    }];

    [IRSearcher sharedInstance].delegate = self;

    // more

    NSMenuItem *item;
    item          = [self.menu itemWithTag: kTagQuicksilverIntegration];
    item.action   = @selector(toggleQuicksilverIntegration:);
    item.onTitle  = @"Quicksilver Integration (installed)";
    item.offTitle = @"Quicksilver Integration (uninstalled)";
    item.state    = [[[ILQuicksilverExtension alloc] init] installed];

    item        = [self.menu itemWithTag: kTagStartAtLoginCheckbox];
    item.title  = @"Start at Login";
    item.state  = 1 /* start at login? */ ? NSOnState : NSOffState;
    item.action = @selector(toggleStartAtLogin:);

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

#pragma mark - NSMenuItem factories

- (NSMenuItem*) menuItemForSignal:(IRSignal*)signal atIndex:(NSUInteger)index {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title   = signal.name;
    item.target  = self;
    item.action  = @selector(send:);
    item.tag     = kSignalTagOffset + index;
    item.toolTip = [NSString stringWithFormat: @"Click to send via %@", signal.peripheral.customizedName];
    if (index < 10) {
        item.keyEquivalent = [NSString stringWithFormat: @"%lu", (unsigned long)index];
    }
    return item;
}

- (NSMenuItem*) menuItemForPeripheral:(IRPeripheral*)peripheral atIndex:(NSUInteger)index {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = [NSString stringWithFormat: @"%@ %@", peripheral.customizedName, peripheral.version];
    item.tag   = kPeripheralTagOffset + index;
    return item;
}

#pragma mark - NSMenuItem actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger signalIndex = ((NSMenuItem*)sender).tag - kSignalTagOffset;
    IRSignal *signal       = (IRSignal*)[self.signals objectInSignalsAtIndex: signalIndex];
    if (!signal.peripheral) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle: @"OK"];
        NSString *message = [NSString stringWithFormat: @"Set \"hostname\" key in ~/.irkit.d/signals/%@.json or remove it and re-learn", signal.name];
        [alert setMessageText: message];
        [alert setAlertStyle: NSWarningAlertStyle];
        [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
        [alert runModal];
        return;
    }
    [signal sendWithCompletion:^(NSError *error) {
        ILLOG( @"sent: %@", error );
    }];
}

- (void) toggleStartAtLogin: (id)sender {
    ILLOG( @"sender: %@", sender );
}

- (void) toggleQuicksilverIntegration: (id)sender {
    ILLOG( @"sender: %@", sender );
    NSMenuItem *item = [self.menu itemWithTag: kTagQuicksilverIntegration];

    if ([[[ILQuicksilverExtension alloc] init] installed]) {
        [self showConfirmToUninstall:^(NSInteger returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                [[[ILQuicksilverExtension alloc] init] uninstall];
                item.state =[[[ILQuicksilverExtension alloc] init] installed] ? NSOnState : NSOffState;
            }
        }];
    }
    else {
        [self showConfirmToInstall:^(NSInteger returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                [[[ILQuicksilverExtension alloc] init] install];
                item.state =[[[ILQuicksilverExtension alloc] init] installed] ? NSOnState : NSOffState;
                NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.blacktree.Quicksilver"];
                if (quicksilvers.count) {
                    [self showConfirmToRelaunchQuicksilver:^(NSInteger returnCode) {
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
}

- (IBAction) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;
}

- (IBAction) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
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

        NSUInteger index = [peripherals indexOfObject: p];
        NSMenuItem *item = [self menuItemForPeripheral: p atIndex: index];
        [self.menu addPeripheralMenuItem: item];
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
