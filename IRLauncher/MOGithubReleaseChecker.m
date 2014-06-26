//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "MOGithubReleaseChecker.h"
#import "ILLog.h"
#import <AFNetworking/AFNetworking.h>

@interface MOGithubReleaseChecker ()

@end

@implementation MOGithubReleaseChecker

- (instancetype) initWithUserName:(NSString*)userName repositoryName:(NSString*)repositoryName {
    self = [super init];
    if (!self) { return nil; }

    _userName       = userName;
    _repositoryName = repositoryName;

    return self;
}

- (void)checkUpdateForVersion:(NSString*)currentVersion foundUpdateBlock:(void (^)(NSString *newVersion))completion {
    ILLOG( @"currentVersion: %@", currentVersion );

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *endpoint                     = [NSString stringWithFormat: @"https://api.github.com/repos/%@/%@/releases", _userName, _repositoryName];
    [manager GET: endpoint
      parameters: nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *tag = ((NSArray*)responseObject)[ 0 ];
        ILLOG( @"tag: %@", tag );

        NSString *assetURLString = tag[@"assets"][ 0 ][ @"url" ];
        // api.github.com -> uploads.github.com
        NSURL *downloadURL = [NSURL URLWithString: ((NSURL*)[NSURL URLWithString: assetURLString]).path
                                    relativeToURL: [NSURL URLWithString: @"https://uploads.github.com/"]];

        if (downloadURL && tag[@"name"]) {
        }
        else {
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        ILLOG(@"error: %@", error);
    }];

}

#pragma mark - Private

@end
