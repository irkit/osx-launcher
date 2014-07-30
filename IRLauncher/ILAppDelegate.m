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

// IRKit API key is defined in APIKey.xcconfig
// Read more at http://getirkit.com/#IRKit-Internet-POST-1-apps
// Get yours to build yourself
static NSString * const kIRKitAPIKey = NSStringize(IRKIT_APIKEY);

static NSString * const kILDistributedNotificationName = @"jp.maaash.IRLauncher.send";
NSString * const kILWillSendSignalNotification         = @"ILWillSendSignalNotification";

@interface ILAppDelegate ()

@property (nonatomic, strong) MOSectionedMenu *sectionedMenu;
@property (nonatomic, strong) MOAnimatingStatusItem *statusItem;
@property (nonatomic, strong) IRSignals *signals;
@property (nonatomic, strong) ILApplicationUpdater *updater;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    ILLOG_CURRENT_METHOD;
    __weak typeof(self) _self = self;

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
    else if (signalFilePath) {
        // do it by myself
        [self performSelector: @selector(postDistributedNotificationToSendFileAtPath:)
                   withObject: signalFilePath
                   afterDelay: 0.];

    }

    if ([MOUpdater didRelaunch]) {
        // relaunched using Updater.app
        NSDictionary *releaseInformation = [MOUpdater releaseInformation];

        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title           = [NSString stringWithFormat: @"Updated to version %@",releaseInformation[ kMOReleaseInformationNewVersionKey ]];
        notification.informativeText = @"Click to show release notes";
        notification.hasActionButton = NO;
        notification.userInfo        = releaseInformation;

        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        center.delegate = self;
        [center deliverNotification: notification];
    }

    [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                        selector: @selector(receivedDistributedNotification:)
                                                            name: nil
                                                          object: nil];
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

    [IRKit startWithAPIKey: kIRKitAPIKey];

    // automatically download, unarchive, update
    _updater = [[ILApplicationUpdater alloc] init];
    [_updater startPeriodicCheck];
}

- (instancetype) init {
    ILLOG_CURRENT_METHOD;
    self = [super init];
    if (!self) { return nil; }

    _signals = [[IRSignals alloc] init];

    _sectionedMenu                       = [[MOSectionedMenu alloc] init];
    _sectionedMenu.menu.autoenablesItems = NO; // enable calling menuItem setEnabled:
    ILMenuDataSource *dataSource = [[ILMenuDataSource alloc] init];
    _sectionedMenu.dataSource = dataSource;
    dataSource.signals        = _signals;
    [dataSource searchForSignals];

    return self;
}

- (BOOL) application:(NSApplication *)sender openFile:(NSString *)filename {
    ILLOG( @"sender: %@, openFile: %@", sender, filename );

    if ([[filename pathExtension] isEqualToString: @"json"]) {
        return YES;
    }

    return NO;
}

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
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

            if (!error) {
                return;
            }

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

@end
