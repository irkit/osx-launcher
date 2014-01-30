//
//  IDVersionChecker.m
//  IRKitDock
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IDMenuletController <NSObject>

- (BOOL)isActive;
- (void)menuletClicked:(NSView*)view;

@end

@interface IDMenuletController : NSObject <IDMenuletController>

@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, strong) NSPopover *popover;

@end
