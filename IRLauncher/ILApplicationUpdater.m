//
//  ILApplicationUpdater.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILLog.h"
#import "ILApplicationUpdater.h"
#import "MOGithubReleaseChecker.h"
#import "MOApplicationUpdater.h"

static NSString * const kILUserDefaultsAutoUpdateKey = @"autoupdate";

@interface ILApplicationUpdater ()

@property (nonatomic) MOGithubReleaseChecker *releaseChecker;

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
    _releaseChecker = [[MOGithubReleaseChecker alloc] initWithUserName: @"mash" repositoryName: @"-----------------"]; // irkit/launcher-macos
    [_releaseChecker checkForVersionNewerThanVersion: version
                                   downloadDirectory: downloadDirectory
                              foundNewerVersionBlock: ^(NSString *newVersion, NSString *releaseInformation, NSURL *downloadedArchive, NSError *error) {
        if (newVersion && downloadedArchive && !error && [self enabled]) {
            [[[MOApplicationUpdater alloc] initWithArchiveURL: downloadedArchive] run];
        }
    }];
}

@end
