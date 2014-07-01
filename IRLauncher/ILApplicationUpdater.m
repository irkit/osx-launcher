//
//  ILApplicationUpdater.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILLog.h"
#import "ILApplicationUpdater.h"
#import <AutoUpdater/AUAutoUpdater.h>
#import <AutoUpdater/AUGithubReleaseChecker.h>
#import <AutoUpdater/AUZipUnarchiver.h>

static NSString * const kILUserDefaultsAutoUpdateKey = @"autoupdate";

@interface ILApplicationUpdater ()

@property (nonatomic) AUGithubReleaseChecker *releaseChecker;
@property (nonatomic) AUAutoUpdater *updater;

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

- (void) run {
    NSString *version           = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *downloadDirectory = [[NSBundle mainBundle] bundlePath];
    _releaseChecker            = [[AUGithubReleaseChecker alloc] initWithUserName: @"mash" repositoryName: @"-----------------"]; // irkit/launcher-macos
    _releaseChecker.unarchiver = [[AUZipUnarchiver alloc] init];
    [_releaseChecker checkForVersionNewerThanVersion: version
                                       downloadDirectory: downloadDirectory
                                  foundNewerVersionBlock: ^(NSString *newVersion, NSString *releaseInformation, NSURL *unarchivedPath, NSError *error) {
        if (newVersion && unarchivedPath && !error && [self enabled]) {
            _updater = [[AUAutoUpdater alloc] initWithSourcePath: unarchivedPath];
            [_updater run];
        }
    }];
}

@end
