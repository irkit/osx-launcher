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
#import "ILUtils.h"
#import "ILFileStore.h"
#import "ILLearnSignalWindowController.h"
#import "NSMenuItem+StateAware.h"
#import "ILConst.h"
#import "ILApplicationUpdater.h"
#import "IRSignals+FileStore.h"
#import "ILSender.h"

// Launcher Extensions
#import "ILLauncherExtension.h"
#import "ILQuicksilverExtension.h"
#import "ILAlfredExtension.h"
// Add other extension headers here!

static const NSInteger kILLauncherExtensionTagOffset = 10000;
static NSString * const kILSupportWebSite            = @"http://github.com/irkit/osx-launcher/issues";
static NSString * const kILOpenSourceWebSite         = @"http://github.com/irkit/osx-launcher";

@interface ILMenuDataSource ()

@property (nonatomic) BOOL searchingForSignals;
@property (nonatomic) IRSignals *signals;
@property (nonatomic) ILLearnSignalWindowController *signalWindowController;
@property (nonatomic) NSArray *launcherExtensions;

@end

@implementation ILMenuDataSource

typedef NS_ENUM (NSUInteger,ILMenuSectionIndex) {
    ILMenuSectionIndexSignals     = 0,
    ILMenuSectionIndexPeripherals = 1,
    ILMenuSectionIndexOptions     = 2,
    ILMenuSectionIndexHelp        = 3,
    ILMenuSectionIndexQuit        = 4
};

typedef NS_ENUM (NSUInteger,ILMenuHelpItemIndex) {
    ILMenuHelpItemIndexOpenSource = 0,
    ILMenuHelpItemIndexSupport    = 1,
    ILMenuHelpItemIndexVersion    = 2
};

typedef NS_ENUM (NSUInteger,ILMenuOptionsItemIndex) {
    ILMenuOptionsItemIndexAutoUpdate = 0,
};

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    [IRSearcher sharedInstance].delegate = self;

    self.launcherExtensions = @[
        [[ILQuicksilverExtension alloc] init],
        [[ILAlfredExtension alloc] init],
        // Add more here!!
                              ];

    return self;
}

- (void) searchForSignals {
    ILLOG_CURRENT_METHOD;

    _searchingForSignals = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                        object: self
                                                      userInfo: @{
         kMOSectionedMenuItemSectionKey: @(ILMenuSectionIndexSignals)
     }];

    __weak typeof(self) _self = self;
    [_signals loadFromFilesUnderDirectory: [ILFileStore signalsDirectory] completion:^(NSError *error) {
        ILLOG( @"loaded" );

        _self.searchingForSignals = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                            object: _self
                                                          userInfo: @{
             kMOSectionedMenuItemSectionKey: @(ILMenuSectionIndexSignals)
         }];
        [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemsAdded
                                                            object: _self
                                                          userInfo: @{
             kMOSectionedMenuItemSectionKey: @(ILMenuSectionIndexSignals)
         }];
    }];
}


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
        return 1 + _launcherExtensions.count;
    }
    break;
    case ILMenuSectionIndexHelp:
    {
        return 3;
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
    item.title         = NSLocalizedString( @"+ Learn New Signal", @"ILMenuDataSource learnNewSignal menu item title" );
    item.target        = self;
    item.action        = @selector(learnNewSignal:);
    item.keyEquivalent = @"+";
    return item;
}

- (void)sectionedMenu:(MOSectionedMenu *)menu updateHeaderItem:(NSMenuItem *)item inSection:(NSUInteger)sectionIndex {
    // header items are all disabled
    [item setEnabled: NO];

    switch (sectionIndex) {
    case ILMenuSectionIndexSignals:
    {
        if (_searchingForSignals) {
            item.title = NSLocalizedString( @"Signals : Searching...", @"ILMenuDataSource searching signals section header title" );
        }
        else {
            item.title = NSLocalizedString( @"Signals", @"ILMenuDataSource not searching signals section header title" );
        }
    }
    break;
    case ILMenuSectionIndexPeripherals:
    {
        if ([IRSearcher sharedInstance].searching) {
            item.title = NSLocalizedString(@"IRKits : Searching...", @"ILMenuDataSource searching IRKits section header title");
        }
        else {
            item.title = NSLocalizedString( @"IRKits", @"ILMenuDataSource not searching IRKits section header title" );
        }
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
        IRSignal *signal = [_signals objectAtIndex: indexPath.item];
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
        case ILMenuOptionsItemIndexAutoUpdate:
        {
            item.title  = NSLocalizedString( @"Auto Update", @"ILMenuDataSource auto update item title" );
            item.target = self;
            item.action = @selector(toggleAutoUpdate:);
            item.state  = [ILApplicationUpdater sharedInstance].enabled;
        }
        break;

        // extensions
        default:
        {
            id<ILLauncherExtension> extension = _launcherExtensions[ indexPath.item - 1 ];
            item.title  = [NSString stringWithFormat: NSLocalizedString(@"Install %@ Extension", @"ILMenuDataSource install %@ extension title"),extension.title];
            item.target = self;
            item.action = @selector(toggleExtensionInstallation:);
            item.tag    = kILLauncherExtensionTagOffset + indexPath.item - 1;
        }
        break;
        }
    }
    break;
    case ILMenuSectionIndexHelp:
    {
        switch (indexPath.item) {
        case ILMenuHelpItemIndexOpenSource:
        {
            item.title  = @"Open Source";
            item.target = self;
            item.action = @selector(showOpenSource:);
        }
        break;
        case ILMenuHelpItemIndexSupport:
        {
            item.title  = @"Support";
            item.target = self;
            item.action = @selector(showHelp:);
        }
        break;
        case ILMenuHelpItemIndexVersion:
        default:
        {
            item.title = [NSString stringWithFormat: @"Version : %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]];
            [item setEnabled: NO];
        }
        break;
        }
    }
    break;
    case ILMenuSectionIndexQuit:
    {
        item.title                     = NSLocalizedString(@"Quit IRLauncher", @"ILMenuDataSource quit");
        item.target                    = self;
        item.action                    = @selector(terminate:);
        item.keyEquivalent             = @"q";
        item.keyEquivalentModifierMask = NSCommandKeyMask;
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
    item.title = signal.name;
    if (signal.peripheral) {
        item.target  = self;
        item.action  = @selector(send:);
        item.toolTip = [NSString stringWithFormat: NSLocalizedString(@"Click to send via %@", @"ILMenuDataSource click to send via %@, tooltip"), signal.peripheral.customizedName];
        if (index < 10) {
            item.keyEquivalent = [NSString stringWithFormat: @"%lu", (unsigned long)index];
        }
        [item setEnabled: YES];
    }
    else {
        item.target  = nil;
        item.action  = nil;
        item.toolTip = @"\"hostname\" key not found";
        [item setEnabled: NO];
    }
    item.tag              = index;
    item.indentationLevel = 1;
}

- (void) updateItem:(NSMenuItem*)item withPeripheral:(IRPeripheral*)peripheral atIndex:(NSUInteger)index {
    if (peripheral.version) {
        item.title = [NSString stringWithFormat: @"%@ %@", peripheral.customizedName, peripheral.version];
    }
    else {
        item.title = [NSString stringWithFormat: @"%@", peripheral.customizedName];
    }
    // You can't click IRKit menuItem, it doesn't do anything
    [item setEnabled: NO];
    item.indentationLevel = 1;
}

#pragma mark - NSMenuItem Actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger signalIndex = ((NSMenuItem*)sender).tag;
    IRSignal *signal       = [_signals objectAtIndex: signalIndex];

    [[NSNotificationCenter defaultCenter] postNotificationName: kILWillSendSignalNotification
                                                        object: self
                                                      userInfo: @{ @"signal": signal }];
    [[[ILSender alloc] init] sendSignalAndAlertOnError: signal];
}

- (void) learnNewSignal :(id)sender {
    ILLOG_CURRENT_METHOD;

    if (![IRKit sharedInstance].peripherals.countOfReadyPeripherals) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle: @"OK"];
        NSString *message = NSLocalizedString(@"No IRKit found in the same Wi-Fi network.\nPlease setup IRKit and connect it to the same network.", @"ILMenuDataSource no IRKits message title");
        [alert setMessageText: message];
        [alert setAlertStyle: NSWarningAlertStyle];
        [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
        [alert runModal];
        return;
    }

    NSPoint pointInScreen = [NSEvent mouseLocation];
    ILLOG( @"pointInScreen: %@", NSStringFromPoint(pointInScreen));

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
    ILLearnSignalWindowController *c = [[ILLearnSignalWindowController alloc] initWithWindow: window];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    [c showWindow: self];
    c.signalDelegate        = self;
    _signalWindowController = c; // retain to keep window showing
}

- (void) toggleAutoUpdate: (id)sender {
    ILLOG( @"sender: %@", sender );
    ILApplicationUpdater *updater = [ILApplicationUpdater sharedInstance];
    [updater enable: !updater.enabled];

    [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemUpdated
                                                        object: self
                                                      userInfo: @{
         kMOSectionedMenuItemIndexPathKey: [MOIndexPath indexPathForItem: ILMenuOptionsItemIndexAutoUpdate
                                                               inSection: ILMenuSectionIndexOptions]
     }];

    if ([updater enabled]) {
        [updater runAndExit];
    }
}

- (void) toggleExtensionInstallation: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSInteger extensionIndex          = ((NSMenuItem*)sender).tag - kILLauncherExtensionTagOffset;
    id<ILLauncherExtension> extension = _launcherExtensions[ extensionIndex ];

    [self showConfirmToInstallExtension: extension completion:^(NSInteger returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            [extension install];
            [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemUpdated
                                                                object: self
                                                              userInfo: @{
                 kMOSectionedMenuItemIndexPathKey: [MOIndexPath indexPathForItem: extensionIndex
                                                                       inSection: ILMenuSectionIndexOptions]
             }];

            if ([extension respondsToSelector: @selector(didFinishInstallation)]) {
                [extension didFinishInstallation];
            }
        }
    }];
}

- (void) showOpenSource: (id)sender {
    ILLOG_CURRENT_METHOD;

    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: kILOpenSourceWebSite]];
}

- (void) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;

    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: kILSupportWebSite]];
}

- (void) terminate: (id)sender {
    ILLOG_CURRENT_METHOD;

    [[NSApplication sharedApplication] terminate: sender];
}

#pragma mark - IRSearcherDelegate

- (void) searcherWillStartSearching:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;

    [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemHeaderUpdated
                                                        object: self
                                                      userInfo: @{
         kMOSectionedMenuItemSectionKey: @(ILMenuSectionIndexPeripherals)
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
         kMOSectionedMenuItemSectionKey: @(ILMenuSectionIndexPeripherals)
     }];

    [[IRSearcher sharedInstance] startSearchingAfterTimeInterval: 5. forTimeInterval: 5.];
}


#pragma mark - ILLearnSignalWindowControllerDelegate

- (void) learnSignalWindowController:(ILLearnSignalWindowController*)c
                 didFinishWithSignal:(IRSignal*)signal
                           withError:(NSError *)error {
    ILLOG( @"signal: %@, error: %@", signal, error );
    [_signalWindowController close];
    _signalWindowController = nil;

    if (error) {
        // Currently, no errors are expected.
        return;
    }

    if (signal) {
        NSError *error = nil;
        BOOL saved     = [ILFileStore saveSignal: signal error: &error];
        if (!saved) {
            NSString *message = error.localizedDescription;
            if ((error.domain == NSCocoaErrorDomain) && (error.code == 4)) {
                message = [NSString stringWithFormat: NSLocalizedString( @"Failed to save to: %@", @"ILMenuDataSource failed to save alert message"), error.userInfo[ NSFilePathErrorKey ]];
            }
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle: @"OK"];
            [alert setMessageText: message];
            [alert setAlertStyle: NSWarningAlertStyle];
            [alert runModal];
            ILLOG( @"saveSignal:error: failed with error: %@", error );
            return;
        }

        [_signals addSignalsObject: signal];
        NSUInteger index = [_signals indexOfSignal: signal];
        [[NSNotificationCenter defaultCenter] postNotificationName: kMOSectionedMenuItemAdded
                                                            object: self
                                                          userInfo: @{
             kMOSectionedMenuItemIndexPathKey: [MOIndexPath indexPathForItem: index
                                                                   inSection: ILMenuSectionIndexSignals]
         }];

        for (id<ILLauncherExtension> extension in _launcherExtensions) {
            if ([extension respondsToSelector: @selector(installed)] && [extension installed]) {
                if ([extension respondsToSelector: @selector(didLearnSignal)]) {
                    [extension didLearnSignal];
                }
            }
        }
    }
}

#pragma mark - Private confirm methods

- (void) showConfirmToInstallExtension:(id<ILLauncherExtension>)extension completion:(void (^)(NSInteger returnCode))callback {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"]; // right most : NSAlertFirstButtonReturn
    [alert addButtonWithTitle: NSLocalizedString(@"Cancel", @"ILMenuDataSource confirm to install cancel")]; // 2nd to right : NSAlertSecondButtonReturn
    [alert setMessageText: [NSString stringWithFormat: NSLocalizedString(@"Install %@ Extension?", @"ILMenuDataSource install extension confirm message"), extension.title]];
    [alert setInformativeText: extension.installInformativeText];
    [alert setAlertStyle: NSWarningAlertStyle];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    NSInteger ret = [alert runModal];
    callback( ret );
}

@end
