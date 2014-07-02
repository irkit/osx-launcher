//
//  ILApplicationUpdater.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILLog.h"
#import "ILApplicationUpdater.h"
#import <AutoUpdater/AUUpdater.h>
#import <AUtoupdater/AUUpdateChecker.h>
#import <AutoUpdater/AUGithubReleaseFetcher.h>
#import <AutoUpdater/AUZipUnarchiver.h>

static NSString * const kILUserDefaultsAutoUpdateKey = @"autoupdate";

@interface ILApplicationUpdater ()

@property (nonatomic) AUUpdateChecker *checker;
@property (nonatomic) AUUpdater *updater;

@end

@implementation ILApplicationUpdater

+ (instancetype) sharedInstance {
    static ILApplicationUpdater *instance;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        instance = [[ILApplicationUpdater alloc] init];
    });
    return instance;
}

- (void) enable: (BOOL)val {
    [[NSUserDefaults standardUserDefaults] setBool: val forKey: kILUserDefaultsAutoUpdateKey];
}

- (BOOL) enabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey: kILUserDefaultsAutoUpdateKey];
}

- (void) runAndExit {
    NSString *version               = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    AUGithubReleaseFetcher *fetcher = [[AUGithubReleaseFetcher alloc] initWithUserName: @"mash" repositoryName: @"-----------------"]; // irkit/launcher-macos
    _checker = [[AUUpdateChecker alloc] initWithFetcher: fetcher
                                             unarchiver: [[AUZipUnarchiver alloc] init]
                                             validators: @[]];
    [_checker checkForVersionNewerThanVersion: version
                       foundNewerVersionBlock:^(NSDictionary *releaseInformation, NSURL *unarchivedPath, NSError *error) {
        if (releaseInformation && unarchivedPath && !error && [self enabled]) {
            // we zipped IRLauncher.app and uploaded IRLauncher.app.zip to github
            NSString *appname = [[NSBundle mainBundle].bundlePath lastPathComponent];
            NSURL *sourceBundlePath = [unarchivedPath URLByAppendingPathComponent: appname];

            if (![[NSFileManager defaultManager] fileExistsAtPath: sourceBundlePath.path]) {
                ILLOG( @"Unarchived asset but %@ not found", sourceBundlePath );
                return;
            }

            _updater = [[AUUpdater alloc] initWithSourcePath: sourceBundlePath];
            [_updater run];
            [[NSRunningApplication currentApplication] terminate];
        }
    }];
}

@end
