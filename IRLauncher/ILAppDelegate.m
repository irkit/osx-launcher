//
//  ILAppDelegate.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILLog.h"
#import "ILVersionChecker.h"
#import "ILUtils.h"
#import "ILSignalsDirectorySearcher.h"
#import "IRKit.h"
#import "ILFileStore.h"
#import "ILMenuProgressView.h"
#import "ILConst.h"
#import "ILMenu.h"
#import "ILQuicksilverExtension.h"
#import "ILSender.h"
#import "NSMenuItem+StateAware.h"
#import "ILLearnSignalWindowController.h"
#import "MOSectionedMenu.h"
#import "ILMenuDataSource.h"

const int kSignalTagOffset                             = 1000;
const int kPeripheralTagOffset                         = 100;
static NSString * const kIRKitAPIKey                   = @"E4D85D012E1B4735BC6F3EBCCCAE4100";
static NSString * const kILDistributedNotificationName = @"jp.maaash.IRLauncher.send";

@interface ILAppDelegate ()

@property (nonatomic, strong) MOSectionedMenu *sectionedMenu;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) IRSignals *signals;

@property (nonatomic, strong) ILLearnSignalWindowController *signalWindowController;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ILLOG_CURRENT_METHOD;

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    ILLOG( @"args: %@", args );
    NSString *lastArgument = (args.count > 1) ? args.lastObject : nil;
    if (lastArgument) {
        BOOL isDuplicateInstance = [[NSRunningApplication runningApplicationsWithBundleIdentifier: [[NSBundle mainBundle] bundleIdentifier]] count] > 1;
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

    ILFileStore *store = [[ILFileStore alloc] init];
    [IRKit setPersistentStore: store]; // call before `startWithAPIKey`
    [IRKit startWithAPIKey: kIRKitAPIKey];

    // setup menu

    self.sectionedMenu = [[MOSectionedMenu alloc] init];
    ILMenuDataSource *dataSource = [[ILMenuDataSource alloc] init];
    dataSource.signals            = _signals;
    self.sectionedMenu.dataSource = dataSource;
    // self.menu.menuDelegate = self;

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 30.];
    [self.statusItem setHighlightMode: YES];
    [self.statusItem setImage: [NSImage imageNamed: @"StatusBarIcon_111"]]; // TODO
    [self.statusItem setAlternateImage: [NSImage imageNamed: @"StatusBarIcon_111"]];
    self.statusItem.menu = self.sectionedMenu.menu;

    // setup menu items
    // signals

    self.signals = [[IRSignals alloc] init];

    // [self.menu setSignalHeaderTitle: @"Signals (Searching...)" animating: YES];

//    [ILSignalsDirectorySearcher findSignalsUnderDirectory: [NSURL fileURLWithPath: [ILFileStore signalsDirectory]]
//                                               completion: ^(NSArray *foundSignals) {
//        [_self.menu setSignalHeaderTitle: @"Signals" animating: NO];
//        [foundSignals enumerateObjectsUsingBlock: ^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
//                IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
//                if (!signal.peripheral) {
//                    // skip signals without hostname
//                    // TODO somehow indicate that we skipped?
//                    return;
//                }
//
//                [_self.signals addSignalsObject: signal];
//                NSUInteger index = [_self.signals indexOfSignal: signal];
//                NSMenuItem *item = [_self menuItemForSignal: signal atIndex: index];
//                [_self.menu addSignalMenuItem: item];
//            }];
//        [self.menu setSignalHeaderTitle: @"Signals" animating: NO];
//    }];

    // peripherals

//    NSArray *peripherals = [IRKit sharedInstance].peripherals.peripherals;
//    [peripherals enumerateObjectsUsingBlock:^(IRPeripheral *peripheral, NSUInteger idx, BOOL *stop) {
//        NSMenuItem *item = [_self menuItemForPeripheral: peripheral atIndex: idx];
//        [_self.menu addPeripheralMenuItem: item];
//    }];

//    [IRSearcher sharedInstance].delegate = self;

    // more

//    NSMenuItem *item;
//
//    item        = [self.menu itemWithTag: kTagLearnSignal];
//    item.action = @selector(learnNewSignal:);
//    item.target = self;
//
//    item          = [self.menu itemWithTag: kTagQuicksilverIntegration];
//    item.action   = @selector(toggleQuicksilverIntegration:);
//    item.target   = self;
//    item.onTitle  = @"Quicksilver Integration (installed)";
//    item.offTitle = @"Quicksilver Integration (uninstalled)";
//    item.state    = [[[ILQuicksilverExtension alloc] init] installed];
//
//    item        = [self.menu itemWithTag: kTagStartAtLoginCheckbox];
//    item.title  = @"Start at Login";
//    item.state  = 1 /* start at login? */ ? NSOnState : NSOffState;
//    item.action = @selector(toggleStartAtLogin:);
//    item.target = self;
}

- (void) notifyUpdate:(NSString*)hostname newVersion:(NSString*)newVersion currentVersion:(NSString*)currentVersion {
    ILLOG( @"hostname: %@ newVersion: %@ currentVersion: %@", hostname, newVersion, currentVersion);

}

- (instancetype) init {
    ILLOG_CURRENT_METHOD;
    self = [super init];
    if (!self) { return nil; }
    return self;
}

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
}

- (void) refreshTitleOfMenuItem: (NSMenuItem*)item withPeripheral:(IRPeripheral*)peripheral {
    if (peripheral.version) {
        item.title = [NSString stringWithFormat: @"%@ %@", peripheral.customizedName, peripheral.version];
    }
    else {
        item.title = [NSString stringWithFormat: @"%@", peripheral.customizedName];
    }
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

#pragma mark - ILLearnSignalWindowControllerDelegate

- (void) learnSignalWindowController:(ILLearnSignalWindowController*)c
                 didFinishWithSignal:(IRSignal*)signal
                           withError:(NSError *)error {
    ILLOG( @"signal: %@, error: %@", signal, error );
    _signalWindowController = nil;

    if (error) {
        // TODO alert? or notification?
        return;
    }

    if (signal) {

        // TODO remove after signal name edit introduced
        signal.name = @"null";

        BOOL saved = [ILFileStore saveSignal: signal];
        if (!saved) {
            // ex: file name overwrite cancelled
            return;
        }

        [_signals addSignalsObject: signal];
        NSUInteger index = [_signals indexOfSignal: signal];
//        NSMenuItem *item = [self menuItemForSignal: signal atIndex: index];
//        [_menu addSignalMenuItem: item];
    }
}

@end
