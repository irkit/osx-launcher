//
//  ILProgressLabelView.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/16.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#define ILLOG_DISABLED 1

#import "ILMenuProgressView.h"
#import "ILLog.h"

@implementation ILMenuProgressView

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;

    [self.indicator setUsesThreadedAnimation: YES];
    [self.indicator setDisplayedWhenStopped: NO];
}

- (void) setAnimating:(BOOL)animating {
    ILLOG( @"animating: %d", animating );

    _animating = animating;
}

- (void) startAnimationIfNeeded {
    ILLOG( @"self: %@ indicator: %@ title: %@ animating: %d", self, self.indicator, self.textField.stringValue, self.animating );

    if (self.animating) {
        NSProgressIndicator *indicator = self.indicator;
        // magic to keep indicator animating
        [indicator setHidden: YES];
        [indicator setHidden: NO];
        [indicator startAnimation: self];
    }
    else {
        [self stopAnimation];
    }
}

- (void) stopAnimation {
    ILLOG_CURRENT_METHOD;

    NSProgressIndicator *indicator = self.indicator;
    [indicator stopAnimation: self];
}

@end
