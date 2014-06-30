//
//  ILApplicationUpdater.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILApplicationUpdater : NSObject

+ (instancetype) sharedInstance;
- (void) enable: (BOOL)val;
- (BOOL) enabled;
- (void) run;

@end
