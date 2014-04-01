//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILMenuletView.h"
#import "ILMenuletController.h"
#import "ILVersionChecker.h"
#import "ILUtils.h"
#import "const.h"

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILVersionChecker *versionChecker;
@property (nonatomic, strong) NSString *newestVersionString;
@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, strong) IRSearcher *searcher;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];
    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength: thickness];

    self.menuletView            = [[ILMenuletView alloc] initWithFrame: (NSRect){.size={thickness, thickness}}];
    self.menuletView.controller = [[ILMenuletController alloc] init];

    [self.item setView: self.menuletView];
    [self.item setHighlightMode: NO];

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
