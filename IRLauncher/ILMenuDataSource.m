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

@implementation ILMenuDataSource

typedef NS_ENUM (NSUInteger,ILMenuSectionIndex) {
    ILMenuSectionIndexSignals     = 0,
    ILMenuSectionIndexPeripherals = 1,
    ILMenuSectionIndexOptions     = 2,
    ILMenuSectionIndexHelp        = 3,
    ILMenuSectionIndexQuit        = 4
};

#pragma mark - MOSectionedMenuDataSource

- (NSUInteger)numberOfSectionsInSectionedMenu:(MOSectionedMenu*)menu {
    return 5;
}

- (NSUInteger)sectionedMenu:(MOSectionedMenu*)menu numberOfItemsInSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    {
        return _signals.countOfSignals;
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
    switch (indexPath.section) {
    case ILMenuSectionIndexSignals:
    {
        IRSignal *signal = [_signals objectAtIndex: indexPath.item];
        return [self menuItemForSignal: signal atIndex: indexPath.item];
    }
    break;
    case ILMenuSectionIndexPeripherals:
    {
        IRPeripheral *peripheral = [[IRKit sharedInstance].peripherals objectAtIndex: indexPath.item];
        return [self menuItemForPeripheral: peripheral atIndex: indexPath.item];
    }
    break;
    case ILMenuSectionIndexOptions:
    {
        NSMenuItem *item;
        switch (indexPath.item) {
        case 0:
        {
            NSMenuItem *item = [[NSMenuItem alloc] init];
            item.title  = @"Start at Login";
            item.target = self;
            item.action = @selector(toggleStartAtLogin:);
            return item;
        }
        break;
        case 1:
        default:
        {
            NSMenuItem *item = [[NSMenuItem alloc] init];
            item.title  = @"Quicksilver Integration";
            item.target = self;
            item.action = @selector(toggleQuicksilverIntegration:);
            return item;
        }
        break;
        }
        return item;

    }
    break;
    case ILMenuSectionIndexHelp:
    {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title  = @"Help";
        item.target = self;
        item.action = @selector(showHelp:);
        return item;
    }
    break;
    case ILMenuSectionIndexQuit:
    {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title  = @"Quit IRLauncher";
        item.target = self;
        item.action = @selector(terminate:);
        return item;
    }
    break;
    default:
        NSAssert(0, @"can't come here");
        return 0;
    }
}

- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu headerItemForSection:(NSUInteger)sectionIndex {
    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = @"Signals";
        return item;
    }
    break;
    case ILMenuSectionIndexPeripherals:
    {
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = @"IRKits";
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

#pragma mark - NSMenuItem factories

- (NSMenuItem*) menuItemForSignal:(IRSignal*)signal atIndex:(NSUInteger)index {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title  = signal.name;
    item.target = self;
    item.action = @selector(send:);
    // item.tag     = kSignalTagOffset + index;
    item.toolTip = [NSString stringWithFormat: @"Click to send via %@", signal.peripheral.customizedName];
    if (index < 10) {
        item.keyEquivalent = [NSString stringWithFormat: @"%lu", (unsigned long)index];
    }
    return item;
}

- (NSMenuItem*) menuItemForPeripheral:(IRPeripheral*)peripheral atIndex:(NSUInteger)index {
//    NSInteger tag   = kPeripheralTagOffset + index;
//    NSMenuItem *ret = [self.menu itemWithTag: tag];
//    if (ret) {
//        return ret;
//    }
//
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = [self menuItemTitleForPeripheral: peripheral];
//    [self refreshTitleOfMenuItem: item withPeripheral: peripheral];
    return item;
}

- (NSString*) menuItemTitleForPeripheral:(IRPeripheral*)peripheral {
    if (peripheral.version) {
        return [NSString stringWithFormat: @"%@ %@", peripheral.customizedName, peripheral.version];
    }
    return [NSString stringWithFormat: @"%@", peripheral.customizedName];
}

#pragma mark - NSMenuItem Actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger signalIndex = 0; // ((NSMenuItem*)sender).tag - kSignalTagOffset;
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

- (IBAction) learnNewSignal :(id)sender {
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

- (IBAction) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;
}

- (IBAction) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
}

@end
