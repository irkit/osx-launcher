//
//  IDVersionChecker.m
//  IRKitDock
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IDVersionChecker.h"
#import <AFNetworking/AFNetworking.h>

@interface IDVersionChecker ()

@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, strong) NSString *newestTagName;

@end

@implementation IDVersionChecker

- (instancetype) init {
    self = [super init];
    if (! self) { return nil; }

    

    return self;
}

- (void)checkWithInterval:(NSTimeInterval)intervalSeconds {
    LOG_CURRENT_METHOD;

    if (_checkTimer) {
        [_checkTimer invalidate];
    }
    _checkTimer = [NSTimer timerWithTimeInterval:intervalSeconds
                                          target:self
                                        selector:@selector(check:)
                                        userInfo:nil
                                         repeats:YES];
    [_checkTimer fire];
}

#pragma mark - Private

- (void) check: (NSTimer*) timer {
    LOG_CURRENT_METHOD;

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"https://api.github.com/repos/irkit/device/tags" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *tag = ((NSArray*)responseObject)[ 0 ];
        LOG( @"tag: %@", tag );
        if ([tag[@"name"] isEqualToString:_newestTagName]) {
            // no new firmware updates
        }
        else {
            // there are new firmware updates
            [self downloadIfNotDownloaded: tag[@"zipball_url"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // let's just ignore errors, we're a version checker, don't worry
        LOG(@"Error: %@", error);
    }];
}

- (void) downloadIfNotDownloaded: (NSString*) zipURL {
    LOG( @"zipURL: %@", zipURL );
}

@end
