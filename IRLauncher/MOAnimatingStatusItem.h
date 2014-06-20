//
//  ILStatusItem.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MOAnimatingStatusItem : NSObject

@property (nonatomic,readonly) NSStatusItem *statusItem;

/// Image to show when not animating
@property (nonatomic) NSImage *image;

/// Image to show when highlighted
@property (nonatomic) NSImage *alternateImage;

@property (nonatomic, copy) NSArray *animationImages;

/// The amount of time it takes to go through one cycle of the images.
@property (nonatomic) NSTimeInterval animationDuration;

@property (nonatomic) NSInteger animationRepeatCount;

@property (nonatomic, readonly) BOOL isAnimating;

- (void) startAnimating;

@end
