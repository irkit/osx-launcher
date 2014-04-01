//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILVersionChecker.h"
#import <AFNetworking/AFNetworking.h>
#import "ILConst.h"

@interface ILVersionChecker ()


@end

@implementation ILVersionChecker

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }


    return self;
}

#pragma mark - Private

- (void) check {
    LOG_CURRENT_METHOD;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET: @"https://api.github.com/repos/irkit/device/releases" parameters: nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *tag = ((NSArray*)responseObject)[ 0 ];
        LOG( @"tag: %@", tag );

        NSString *assetURLString = tag[@"assets"][ 0 ][ @"url" ];
        // api.github.com -> uploads.github.com
        NSURL *downloadURL = [NSURL URLWithString: ((NSURL*)[NSURL URLWithString: assetURLString]).path
                                    relativeToURL: [NSURL URLWithString: @"https://uploads.github.com/"]];

        if (downloadURL && tag[@"name"]) {
            [self.delegate checker: self
                    didFindVersion: tag[@"name"]
                             onURL: downloadURL];
        }
        else {
            NSError *error = [NSError errorWithDomain: IRLauncherErrorDomain code: IRLauncherErrorCodeInvalidTag userInfo: nil];
            [self.delegate checker: self
             didFailCheckWithError: error];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"Error: %@", error);
        [self.delegate checker: self
         didFailCheckWithError: error];
    }];
}

@end
