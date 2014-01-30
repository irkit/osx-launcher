//
//  IDVersionChecker.h
//  IRKitDock
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDVersionCheckerDelegate;

@interface IDVersionChecker : NSObject

@property (nonatomic, weak) id<IDVersionCheckerDelegate> delegate;

- (void)checkWithInterval:(NSTimeInterval) intervalSeconds;

@end

@protocol IDVersionCheckerDelegate <NSObject>

@required
- (void) checker: (IDVersionChecker*) checker didDownloadNewFirmware: (NSData*) data;

@end