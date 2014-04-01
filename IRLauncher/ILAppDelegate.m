//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILMenuletView.h"
#import "ILVersionChecker.h"
#import "ILUtils.h"
#import "const.h"

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILMenu *menu;
@property (nonatomic, strong) ILVersionChecker *versionChecker;
@property (nonatomic, strong) NSString *newestVersionString;
@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, strong) IRSearcher *searcher;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    __weak typeof(self) _self = self;
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];

    self.menuletView             = [[ILMenuletView alloc] initWithFrame: (NSRect){.size={thickness, thickness}}];
    self.menuletView.onMouseDown = (ILEventBlock)^(NSEvent *event) {
        [_self.item popUpStatusItemMenu: _self.menu];
    };

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength: thickness];
    [self.item setView: self.menuletView];
    [self.item setHighlightMode: NO];

    NSArray *nibEntries = @[];
    [[NSBundle mainBundle] loadNibNamed: @"MainMenu" owner: self topLevelObjects: &nibEntries];
    self.menu = (ILMenu*)[ILUtils firstObjectOf: nibEntries meetsBlock:^BOOL (id obj, NSUInteger idx) {
        if ([obj isKindOfClass: [ILMenu class]]) {
            return YES;
        }
        return NO;
    }];
    // self.item.menu = menu;

    // self.menuletView.menu = menu;

    self.versionChecker          = [[ILVersionChecker alloc] init];
    self.versionChecker.delegate = self;

    // check every 24 hours
    [self checkWithInterval: 24. * 60. * 60.];
}

- (void)checkWithInterval:(NSTimeInterval)intervalSeconds {
    LOG_CURRENT_METHOD;

    if (_checkTimer) {
        [_checkTimer invalidate];
    }
    _checkTimer = [NSTimer timerWithTimeInterval: intervalSeconds
                                          target: self
                                        selector: @selector(checkReleasedVersion:)
                                        userInfo: nil
                                         repeats: YES];
    [_checkTimer fire];
}

- (void) checkReleasedVersion: (NSTimer*) timer {
    [_versionChecker check];
}

- (void) checkIfIRKitUpdated {
    LOG( @"version: %@", _newestVersionString );

    [IRSearcher sharedInstance].delegate = self;
    // [[IRSearcher sharedInstance] startSearchingForInterval:60.]; // 1min.
}

- (void) notifyUpdate:(NSString*)hostname newVersion:(NSString*)newVersion currentVersion:(NSString*)currentVersion {
    LOG( @"hostname: %@ newVersion: %@ currentVersion: %@", hostname, newVersion, currentVersion);

}

- (void) showHelp: (id)sender {
    LOG_CURRENT_METHOD;
}

- (void) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
}

#pragma mark - IRSearcherDelegate

- (void) searcher:(IRSearcher *)searcher didResolveService:(NSNetService *)service {
    LOG( @"service: %@", service );

    __weak ILAppDelegate *_self   = self;
    __weak NSNetService *_service = service;
    [ILUtils getModelNameAndVersion: service.hostName withCompletion:^(NSString *modelName, NSString *version) {
        LOG(@"modelName: %@, version: %@", modelName, version);
        if ([modelName isEqualToString: IRKitModelName]) {
            if ([ILUtils releasedVersionString: _self.newestVersionString isNewerThanPeripheralVersion: version]) {
                [_self notifyUpdate: _service.hostName newVersion: _self.newestVersionString currentVersion: version];
            }
        }
    }];
}

#pragma mark - ILVersionCheckerDelegate

- (void) checker:(ILVersionChecker *)checker didFindVersion:(NSString *)versionString onURL:(NSURL *)assetURL {
    LOG( @"checker: %@", checker );

    _newestVersionString = versionString;

    NSURL *pathURL = [ILUtils URLPathForVersion: versionString];
    if ([[NSFileManager defaultManager] fileExistsAtPath: pathURL.absoluteString]) {
        // already downloaded
        [self checkIfIRKitUpdated];
    }
    else {
        __weak ILAppDelegate *_self = self;
        [ILUtils downloadAssetURL: assetURL toPathURL: pathURL completion:^(NSError* error) {
            if (!error) {
                [_self checkIfIRKitUpdated];
            }
        }];
    }
}

- (void) checker:(ILVersionChecker *)checker didFailCheckWithError:(NSError *)error {
    LOG( @"error: %@", error );
    // we can check on next timer, ignore errors
}

@end
