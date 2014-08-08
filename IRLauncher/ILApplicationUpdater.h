//
//  ILApplicationUpdater.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kILUserDefaultsAutoUpdateKey;

@interface ILApplicationUpdater : NSObject

+ (instancetype) sharedInstance;
- (void) startPeriodicCheck;
- (void) enable: (BOOL)val;
- (BOOL) enabled;
- (void) runAndExit;

@end
