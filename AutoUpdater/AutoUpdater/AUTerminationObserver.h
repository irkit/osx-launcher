//
//  AUTerminationListener.h
//  AutoUpdater
//
//  Created by Masakazu Ohtsuka on 2014/07/01.
//  Copyright (c) 2014年 maaash.jp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AUTerminationObserver : NSObject

@property (nonatomic) NSTimeInterval timeout;

- (void) observeTerminationOfBundleIdentifier:(NSString*)bundleIdentifier completion:(void (^)(NSError* error))completion;

@end
