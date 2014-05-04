//
//  ILUSBWatcher.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/18.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kILUSBWatcherNotificationAdded;
extern NSString * const kILUSBWatcherNotificationRemoved;
extern NSString * const kILUSBWatcherNotificationDeviceNameKey;
extern NSString * const kILUSBWatcherNotificationLocationIDKey;
extern NSString * const kILUSBWatcherNotificationVendorIDKey;
extern NSString * const kILUSBWatcherNotificationProductIDKey;

@interface ILUSBWatcher : NSObject

@property (nonatomic) BOOL isRunning;

+ (instancetype) sharedInstance;
- (void) startWatchingUSB;
- (void) stopWatchingUSB;

@end
