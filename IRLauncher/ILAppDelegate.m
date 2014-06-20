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
#import "ILFileStore.h"
#import "ILSender.h"
#import "ILConst.h"
#import "ILStatusItem.h"

const int kSignalTagOffset                             = 1000;
const int kPeripheralTagOffset                         = 100;
static NSString * const kIRKitAPIKey                   = @"E4D85D012E1B4735BC6F3EBCCCAE4100";
static NSString * const kILDistributedNotificationName = @"jp.maaash.IRLauncher.send";

@interface ILAppDelegate ()

@property (nonatomic, strong) MOSectionedMenu *sectionedMenu;
@property (nonatomic, strong) MOAnimatingStatusItem *statusItem;
@property (nonatomic, strong) IRSignals *signals;

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

    // Initialize statusItem in 1 process only.
    // We don't want another statusItem to show and immediately disappear,
    // when duplicate process launches and terminates.
    _statusItem                 = [[ILStatusItem alloc] init];
    _statusItem.statusItem.menu = _sectionedMenu.menu;

    ILFileStore *store = [[ILFileStore alloc] init];
    [IRKit setPersistentStore: store]; // call before `startWithAPIKey`
    [IRKit startWithAPIKey: kIRKitAPIKey];
}

- (void) notifyUpdate:(NSString*)hostname newVersion:(NSString*)newVersion currentVersion:(NSString*)currentVersion {
    ILLOG( @"hostname: %@ newVersion: %@ currentVersion: %@", hostname, newVersion, currentVersion);

}

- (instancetype) init {
    ILLOG_CURRENT_METHOD;
    self = [super init];
    if (!self) { return nil; }

    _signals = [[IRSignals alloc] init];

    _sectionedMenu = [[MOSectionedMenu alloc] init];
    ILMenuDataSource *dataSource = [[ILMenuDataSource alloc] init];
    _sectionedMenu.dataSource = dataSource;
    dataSource.signals        = _signals;
    [dataSource searchForSignals];

    return self;
}

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
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

        [_statusItem startAnimating];

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
