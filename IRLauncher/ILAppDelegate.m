//
//  ILAppDelegate.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILLog.h"
#import "MOSectionedMenu.h"
#import "IRSignals.h"
#import "ILMenuDataSource.h"
#import "ILSender.h"
#import "ILConst.h"
#import "ILStatusItem.h"
#import "ILApplicationUpdater.h"
#import <MOAutoUpdater/MOUpdater.h>

static NSString * const kILDistributedNotificationName = @"jp.maaash.IRLauncher.send";
NSString * const kILWillSendSignalNotification         = @"ILWillSendSignalNotification";

@interface ILAppDelegate ()

@property (nonatomic, strong) MOSectionedMenu *sectionedMenu;
@property (nonatomic, strong) MOAnimatingStatusItem *statusItem;
@property (nonatomic, strong) IRSignals *signals;
@property (nonatomic, strong) ILApplicationUpdater *updater;
@property (nonatomic, strong) NSMutableArray *pendingSignalFiles;
@property (nonatomic) BOOL didLaunch;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ILLOG_CURRENT_METHOD;

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    ILLOG( @"args: %@", args );

    NSString *signalFilePath = (args.count == 2) ? args[ 1 ] : nil;

    BOOL isDuplicateInstance = [[NSRunningApplication runningApplicationsWithBundleIdentifier: [[NSBundle mainBundle] bundleIdentifier]] count] > 1;
    if (isDuplicateInstance) {
        ILLOG( @"found duplicate" );

        // ex: launched using Quicksilver
        if (signalFilePath) {
            // send using living app, to animate status bar icon
            [self postDistributedNotificationToSendFileAtPath: signalFilePath];
        }
        [NSApp terminate: nil];
        return;
    }

    [self setupSingleInstance];

    if (signalFilePath) {
        // fresh launch with signal JSON file as argument
        [self postDistributedNotificationToSendFileAtPath: signalFilePath];
    }
    else if (_pendingSignalFiles.count) {
        // double clicked signal JSON file before launch
        for (NSString *filename in _pendingSignalFiles) {
            [self postDistributedNotificationToSendFileAtPath: filename];
        }
        _pendingSignalFiles = nil; // don't use after launch
    }

    if ([MOUpdater didRelaunch]) {
        // relaunched using Updater.app
        NSDictionary *releaseInformation = [MOUpdater releaseInformation];
        ILLOG( @"didRelaunch with releaseInformation: %@", releaseInformation );

        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title           = [NSString stringWithFormat: NSLocalizedString(@"Updated to version %@", @"ILAppDelegate updated to version notification title"),releaseInformation[ kMOReleaseInformationNewVersionKey ]];
        notification.informativeText = NSLocalizedString(@"Click to show release notes", @"ILAppDelegate updated to version informative text");
        notification.hasActionButton = NO;
        notification.userInfo        = releaseInformation;

        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        center.delegate = self;
        [center deliverNotification: notification];
    }

    _didLaunch = YES;
}

// Things I don't want in duplicate instances
- (void) setupSingleInstance {
    ILLOG_CURRENT_METHOD;
    __weak typeof(self) _self = self;

    [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                        selector: @selector(receivedDistributedNotification:)
                                                            name: kILDistributedNotificationName
                                                          object: nil
                                              suspensionBehavior: NSNotificationSuspensionBehaviorDeliverImmediately];
    [[NSNotificationCenter defaultCenter] addObserverForName: kILWillSendSignalNotification
                                                      object: nil
                                                       queue: nil
                                                  usingBlock:^(NSNotification *note) {
        ILLOG( @"will send" );
        [_self.statusItem startAnimating];
    }];

    // Initialize statusItem in 1 process only.
    // We don't want another statusItem to show and immediately disappear,
    // when duplicate process launches and terminates.
    _statusItem                 = [[ILStatusItem alloc] init];
    _statusItem.statusItem.menu = _sectionedMenu.menu;
}

- (BOOL) application:(NSApplication *)sender openFile:(NSString *)filename {
    ILLOG( @"sender: %@, openFile: %@", sender, filename );

    if ([[filename pathExtension] isEqualToString: @"json"]) {
        if (_didLaunch) {
            // double clicked on signal JSON file while already launched
            [self postDistributedNotificationToSendFileAtPath: filename];
        }
        else {
            // double clicked on singal JSON file before launch
            // send after launched
            [_pendingSignalFiles addObject: filename];
        }
        return YES;
    }

    return NO;
}

- (instancetype) init {
    ILLOG_CURRENT_METHOD;
    self = [super init];
    if (!self) { return nil; }
    return self;
}

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;

    [[NSUserDefaults standardUserDefaults] registerDefaults: @{ kILUserDefaultsAutoUpdateKey: @YES }];

    _signals            = [[IRSignals alloc] init];
    _pendingSignalFiles = @[].mutableCopy;

    _sectionedMenu                       = [[MOSectionedMenu alloc] init];
    _sectionedMenu.menu.autoenablesItems = NO; // enable calling menuItem setEnabled:
    ILMenuDataSource *dataSource = [[ILMenuDataSource alloc] init];
    _sectionedMenu.dataSource = dataSource;
    dataSource.signals        = _signals;
    [dataSource searchForSignals];

    [IRKit startWithAPIKey: [self APIKey]];

    // automatically download, unarchive, update
    _updater = [[ILApplicationUpdater alloc] init];
    [_updater startPeriodicCheck];
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
}

#pragma mark - misc

- (NSString*) APIKey {
    NSString *plistFile = [[NSBundle mainBundle] pathForResource: @"APIKey" ofType: @"plist"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath: plistFile]) {
        NSLog(@"!!!\nRead README-APIKey.txt\n!!!");
        abort();
        return nil;
    }

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: plistFile];
    NSString *ret      = dict[@"IRKitAPIKey"];
    if (!ret) {
        NSLog(@"!!!\nRead README-APIKey.txt\n!!!");
        abort();
        return nil;
    }
    return ret;
}

#pragma mark - NSUserNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
    ILLOG( @"notification: %@", notification );

    NSString *url = notification.userInfo[ kMOReleaseInformationURLKey ];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: url]];
}

#pragma mark - NSDistributedNotification related

- (void)postDistributedNotificationToSendFileAtPath: (NSString*)path {
    ILLOG( @"path: %@", path );

    [[NSDistributedNotificationCenter defaultCenter] postNotificationName: kILDistributedNotificationName
                                                                   object: [[NSBundle mainBundle] bundleIdentifier]
                                                                 userInfo: @{ @"path": path }
                                                       deliverImmediately: YES];
}

- (void)receivedDistributedNotification:(NSNotification*)notification {
    ILLOG( @"sender: %@", notification );
    if ([notification.name isEqualToString: kILDistributedNotificationName]) {
        NSString *path = notification.userInfo[ @"path" ];
        ILLOG( @"will send: %@", path );

        [[[ILSender alloc] init] sendFileAtPathAndAlertOnError: path];
    }
}

@end
