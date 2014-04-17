//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef BOOL (^ILEventBlock)(NSEvent *event);

@interface ILMenuletView : NSView

@property (nonatomic, copy) ILEventBlock onMouseDown;

@end
