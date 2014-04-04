//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILVersionChecker.h"
#import <AFNetworking/AFNetworking.h>
#import "const.h"

@interface ILVersionChecker ()

@end

@implementation ILVersionChecker

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }


    return self;
}

- (void)checkUpdateForVersion:(NSString*)currentVersion foundUpdateBlock:(void (^)(NSString *newVersion))completion {
    ILLOG( @"currentVersion: %@", currentVersion );

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET: @"https://api.github.com/repos/irkit/device/releases" parameters: nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
