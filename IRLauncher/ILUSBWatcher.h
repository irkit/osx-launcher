//
//  ILUSBWatcher.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/18.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSUInteger kUSBEventPlugged;
extern const NSUInteger kUSBEventUnplugged;

typedef void (^USBDeviceMatchedBlock)(NSUInteger event, NSDictionary *info);

@interface ILUSBWatcher : NSObject

@property (nonatomic) BOOL isRunning;

+ (instancetype) sharedInstance;
- (int) watchUSBMatchingPredicate:(NSPredicate*)predicate matchedBlock:(USBDeviceMatchedBlock)block;
- (void) stop;

@end
