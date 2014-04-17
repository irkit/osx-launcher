//
//  ILProgressLabelView.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/16.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ILMenuProgressView : NSView

@property (nonatomic, weak) IBOutlet NSProgressIndicator *indicator;
@property (nonatomic, weak) IBOutlet NSTextField *textField;
@property (nonatomic) BOOL animating;

- (void) startAnimationIfNeeded;
- (void) stopAnimation;

@end
