//
//  ILStatusItem.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/20.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILStatusItem.h"

@implementation ILStatusItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.image           = [NSImage imageNamed: @"StatusBarIcon_111"];
        self.alternateImage  = [NSImage imageNamed: @"StatusBarIconAlt"];
        self.animationImages = @[
            [NSImage imageNamed: @"StatusBarIcon_100"],
            [NSImage imageNamed: @"StatusBarIcon_010"],
            [NSImage imageNamed: @"StatusBarIcon_001"],
            [NSImage imageNamed: @"StatusBarIcon_000"],
                               ];
        self.animationDuration    = 1;
        self.animationRepeatCount = 3;
    }
    return self;
}

@end
