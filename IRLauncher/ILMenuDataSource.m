//
//  ILMenuDataSource.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuDataSource.h"
#import "ILLog.h"
#import "IRKit.h"
#import "ILMenuProgressView.h"
#import "ILUtils.h"
#import "ILSignalsDirectorySearcher.h"
#import "ILFileStore.h"

@interface ILMenuDataSource ()

@property (nonatomic) BOOL searchingForSignals;
@property (nonatomic) IRSignals *signals;

@end

@implementation ILMenuDataSource

typedef NS_ENUM (NSUInteger,ILMenuSectionIndex) {
    ILMenuSectionIndexSignals     = 0,
    ILMenuSectionIndexPeripherals = 1,
    ILMenuSectionIndexOptions     = 2,
    ILMenuSectionIndexHelp        = 3,
    ILMenuSectionIndexQuit        = 4
};

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    [IRSearcher sharedInstance].delegate = self;

    return self;
}

- (void) searchForSignals {
    ILLOG_CURRENT_METHOD;

    _searchingForSignals = YES;

    [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                        object: self
                                                      userInfo: @{
         kMOSectionedMenuItemSectionKey: @0
     }];

    __weak typeof(self) _self = self;
    [ILSignalsDirectorySearcher findSignalsUnderDirectory: [NSURL fileURLWithPath: [ILFileStore signalsDirectory]]
                                               completion: ^(NSArray *foundSignals) {

        _self.searchingForSignals = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                            object: _self
                                                          userInfo: @{
             kMOSectionedMenuItemSectionKey: @0
         }];

        [foundSignals enumerateObjectsUsingBlock: ^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
                IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
                if (!signal.peripheral) {
                    // skip signals without hostname
                    // TODO somehow indicate that we skipped?
                    return;
                }

                [_self.signals addSignalsObject: signal];
                NSUInteger index = [_self.signals indexOfSignal: signal];

                [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemAdded
                                                                    object: _self
                                                                  userInfo: @{
                     kMOSectionedMenuItemIndexPathKey: [MOIndexPath indexPathForItem: index inSection: 0]
                 }];
            }];
    }];
}

- (NSArray*) signalsWithPeripheral {
    return [_signals.signals filteredArrayUsingPredicate: [NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary *bindings) {
            return !!((IRSignal*)evaluatedObject).peripheral;
        }]];
}

#pragma mark - MOSectionedMenuDataSource

- (NSUInteger)numberOfSectionsInSectionedMenu:(MOSectionedMenu*)menu {
    return 5;
}

- (NSUInteger)sectionedMenu:(MOSectionedMenu*)menu numberOfItemsInSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    {
        return [self signalsWithPeripheral].count;
    }
    break;
    case ILMenuSectionIndexPeripherals:
    {
        return [IRKit sharedInstance].peripherals.countOfReadyPeripherals;
    }
    break;
    case ILMenuSectionIndexOptions:
    {
        return 2;
    }
    break;
    case ILMenuSectionIndexHelp:
    {
        return 1;
    }
    break;
    case ILMenuSectionIndexQuit:
    {
        return 1;
    }
    break;
    default:
        NSAssert(0, @"can't come here");
        return 0;
    }
}

- (BOOL)sectionedMenu:(MOSectionedMenu*)menu hasHeaderForSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    case ILMenuSectionIndexPeripherals:
    {
        return YES;
    }
    default:
    {
        return NO;
    }
    }
}

- (BOOL)sectionedMenu:(MOSectionedMenu*)menu hasFooterForSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    {
        return YES;
    }
    default:
    {
        return NO;
    }
    }
}

- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu itemForIndexPath:(MOIndexPath*)indexPath {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    [self sectionedMenu: menu updateItem: item atIndexPath: indexPath];
    return item;
}

- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu headerItemForSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    case ILMenuSectionIndexPeripherals:
    {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [self sectionedMenu: menu updateHeaderItem: item inSection: sectionIndex];
        return item;
    }
    break;
    default:
    {
        return nil;
    }
    }
}

- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu footerItemForSection:(NSUInteger)sectionIndex {
    if (sectionIndex != ILMenuSectionIndexSignals) {
        return nil;
    }

    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title         = @"Learn New Signal";
    item.target        = self;
    item.action        = @selector(learnNewSignal:);
    item.keyEquivalent = @"+";
    return item;
}

- (void)sectionedMenu:(MOSectionedMenu *)menu updateHeaderItem:(NSMenuItem *)item inSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    {
        if (![item.view isKindOfClass: [ILMenuProgressView class]]) {
            item.view = [ILUtils loadClassNamed: @"ILMenuProgressView"];
        }
        ILMenuProgressView *view = (ILMenuProgressView*)item.view;
        if (_searchingForSignals) {
            view.animating = YES;
            [view.textField setStringValue: @"Signals (Searching...)"];
        }
        else {
            view.animating = NO;
            [view.textField setStringValue: @"Signals"];
        }
        [view startAnimationIfNeeded];
    }
    break;
    case ILMenuSectionIndexPeripherals:
    {
        if (![item.view isKindOfClass: [ILMenuProgressView class]]) {
            item.view = [ILUtils loadClassNamed: @"ILMenuProgressView"];
        }
        ILMenuProgressView *view = (ILMenuProgressView*)item.view;
        if ([IRSearcher sharedInstance].searching) {
            view.animating = YES;
            [view.textField setStringValue: @"IRKits (Searching...)"];
        }
        else {
            view.animating = NO;
            [view.textField setStringValue: @"IRKits"];
        }
        [view startAnimationIfNeeded];
    }
    break;
    default:
        break;
    }
}

- (void)sectionedMenu:(MOSectionedMenu *)menu updateFooterItem:(NSMenuItem *)item inSection:(NSUInteger)sectionIndex {
}

- (void)sectionedMenu:(MOSectionedMenu *)menu updateItem:(NSMenuItem *)item atIndexPath:(MOIndexPath *)indexPath {
    switch (indexPath.section) {
    case ILMenuSectionIndexSignals:
    {
        IRSignal *signal = [[self signalsWithPeripheral] objectAtIndex: indexPath.item];
        [self updateItem: item withSignal: signal atIndex: indexPath.item];
    }
    break;
    case ILMenuSectionIndexPeripherals:
    {
        IRPeripheral *peripheral = [[IRKit sharedInstance].peripherals objectAtIndex: indexPath.item];
        [self updateItem: item withPeripheral: peripheral atIndex: indexPath.item];
    }
    break;
    case ILMenuSectionIndexOptions:
    {
        switch (indexPath.item) {
        case 0:
        {
            item.title  = @"Start at Login";
            item.target = self;
            item.action = @selector(toggleStartAtLogin:);
        }
        break;
        case 1:
        default:
        {
            item.title  = @"Quicksilver Integration";
            item.target = self;
            item.action = @selector(toggleQuicksilverIntegration:);
        }
        break;
        }
    }
    break;
    case ILMenuSectionIndexHelp:
    {
        item.title  = @"Help";
        item.target = self;
        item.action = @selector(showHelp:);
    }
    break;
    case ILMenuSectionIndexQuit:
    {
        item.title  = @"Quit IRLauncher";
        item.target = self;
        item.action = @selector(terminate:);
    }
    break;
    default:
        NSAssert(0, @"can't come here");
    }
}

- (void) menuWillOpen:(NSMenu *)menu {
    ILLOG_CURRENT_METHOD;

    [[IRSearcher sharedInstance] startSearchingForTimeInterval: 5.];
}

- (void) menuDidClose:(NSMenu *)menu {
    ILLOG_CURRENT_METHOD;

    [[IRSearcher sharedInstance] stop];
}

#pragma mark - NSMenuItem factories

- (void) updateItem:(NSMenuItem*)item withSignal:(IRSignal*)signal atIndex:(NSUInteger)index {
    item.title   = signal.name;
    item.target  = self;
    item.action  = @selector(send:);
    item.toolTip = [NSString stringWithFormat: @"Click to send via %@", signal.peripheral.customizedName];
    if (index < 10) {
        item.keyEquivalent = [NSString stringWithFormat: @"%lu", (unsigned long)index];
    }
}

- (void) updateItem:(NSMenuItem*)item withPeripheral:(IRPeripheral*)peripheral atIndex:(NSUInteger)index {
    if (peripheral.version) {
        item.title = [NSString stringWithFormat: @"%@ %@", peripheral.customizedName, peripheral.version];
    }
    else {
        item.title = [NSString stringWithFormat: @"%@", peripheral.customizedName];
    }
}

#pragma mark - NSMenuItem Actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger signalIndex = 0; // ((NSMenuItem*)sender).tag - kSignalTagOffset;
    IRSignal *signal       = (IRSignal*)[[self signalsWithPeripheral] objectAtIndex: signalIndex];
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

- (void) learnNewSignal :(id)sender {
    ILLOG_CURRENT_METHOD;

    NSEvent *event        = [NSApp currentEvent];
    NSPoint location      = [event locationInWindow];
    NSPoint pointInScreen = [NSEvent mouseLocation];
    ILLOG( @"locationInWindow: %@, screen: %@", NSStringFromPoint(location), NSStringFromPoint(pointInScreen));

    if (pointInScreen.x + 640 > [NSScreen mainScreen].frame.size.width) {
        pointInScreen.x = [NSScreen mainScreen].frame.size.width - 640;
    }
    if (pointInScreen.y + 360 > [NSScreen mainScreen].frame.size.height) {
        pointInScreen.y = [NSScreen mainScreen].frame.size.height - 360;
    }
    NSRect rect = {
        { pointInScreen.x, pointInScreen.y },
        { 640, 360 }
    };
    NSWindow *window = [[NSWindow alloc] initWithContentRect: rect
                                                   styleMask: NSTitledWindowMask | NSClosableWindowMask
                                                     backing: NSBackingStoreBuffered
                                                       defer: NO];
//    ILLearnSignalWindowController *c = [[ILLearnSignalWindowController alloc] initWithWindow: window];
//    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
//    [c showWindow: self];
//    c.signalDelegate        = self;
//    _signalWindowController = c; // retain to keep window showing
}

- (void) toggleStartAtLogin: (id)sender {
    ILLOG( @"sender: %@", sender );
}

- (void) toggleQuicksilverIntegration: (id)sender {
    ILLOG( @"sender: %@", sender );
//    NSMenuItem *item = [self.menu itemWithTag: kTagQuicksilverIntegration];
//
//    if ([[[ILQuicksilverExtension alloc] init] installed]) {
//        [self showConfirmToUninstall:^(NSInteger returnCode) {
//            if (returnCode == NSAlertFirstButtonReturn) {
//                [[[ILQuicksilverExtension alloc] init] uninstall];
//                item.state =[[[ILQuicksilverExtension alloc] init] installed] ? NSOnState : NSOffState;
//            }
//        }];
//    }
//    else {
//        [self showConfirmToInstall:^(NSInteger returnCode) {
//            if (returnCode == NSAlertFirstButtonReturn) {
//                [[[ILQuicksilverExtension alloc] init] install];
//                item.state =[[[ILQuicksilverExtension alloc] init] installed] ? NSOnState : NSOffState;
//                NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.blacktree.Quicksilver"];
//                if (quicksilvers.count) {
//                    [self showConfirmToRelaunchQuicksilver:^(NSInteger returnCode) {
//                            NSRunningApplication *q = quicksilvers[ 0 ];
//                            BOOL success = [q terminate];
//                            if (!success) {
//                                ILLOG( @"failed to terminate quicksilver" );
//                            }
//                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                                    NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: @"com.blacktree.Quicksilver"];
//                                    if (quicksilvers.count) {
//                                        ILLOG( @"failed to terminate quicksilver" );
//                                        return;
//                                    }
//                                    BOOL success = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier: @"com.blacktree.Quicksilver"
//                                                                                                        options: NSWorkspaceLaunchDefault
//                                                                                 additionalEventParamDescriptor: NULL
//                                                                                               launchIdentifier: NULL];
//                                    if (!success) {
//                                        ILLOG( @"failed to launch quicksilver" );
//                                    }
//                                });
//                        }];
//                }
//            }
//        }];
//    }
}

- (void) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;
}

- (void) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
}

#pragma mark - IRSearcherDelegate

- (void) searcherWillStartSearching:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;

    [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                        object: self
                                                      userInfo: @{
         kMOSectionedMenuItemSectionKey: @1
     }];
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
        [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemAdded
                                                            object: self
                                                          userInfo: @{
             kMOSectionedMenuItemIndexPathKey: [MOIndexPath indexPathForItem: index inSection: 1]
         }];
    }
    if (!p.deviceid) {
        __weak typeof(self) _self = self;
        __weak typeof(p)    _p    = p;
        [p getKeyWithCompletion:^{
            IRPeripherals *peripherals = [IRKit sharedInstance].peripherals;
            NSUInteger index = [peripherals indexOfObject: _p];
            [peripherals save];
            [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemUpdated
                                                                object: _self
                                                              userInfo: @{
                 kMOSectionedMenuItemIndexPathKey: [MOIndexPath indexPathForItem: index inSection: 1]
             }];
        }];
    }
}

- (void) searcherDidTimeout:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;

    [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                        object: self
                                                      userInfo: @{
         kMOSectionedMenuItemSectionKey: @1
     }];

    [[IRSearcher sharedInstance] startSearchingAfterTimeInterval: 5. forTimeInterval: 5.];
}

@end
