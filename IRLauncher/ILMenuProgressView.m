//
//  ILProgressLabelView.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/16.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuProgressView.h"

@implementation ILMenuProgressView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame: frameRect];
    if (!self) { return self; }

    [self.indicator setUsesThreadedAnimation: YES];

    return self;
}

- (void) startAnimationIfNeeded {
    if (self.animating) {
        NSProgressIndicator *indicator = self.indicator;
        [indicator performSelector: @selector(startAnimation:)
                        withObject: nil
                        afterDelay: 0.0
                           inModes: [NSArray arrayWithObject: NSEventTrackingRunLoopMode]];
    }
}

- (void) stopAnimation {
    NSProgressIndicator *indicator = self.indicator;
    [indicator stopAnimation: nil];
}

@end
