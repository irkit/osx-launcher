//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ILMenuletController <NSObject>

- (BOOL)isActive;
- (void)menuletClicked:(NSView*)view;

@end

@interface ILMenuletController : NSObject <ILMenuletController>

@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, strong) NSPopover *popover;

@end
