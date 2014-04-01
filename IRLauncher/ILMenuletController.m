//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuletController.h"
#import "ILAppDelegate.h"
#import "ILPopoverController.h"

@implementation ILMenuletController

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    return self;
}

- (void)_setupPopover {
    if (!self.popover) {
        self.popover                       = [[NSPopover alloc] init];
        self.popover.contentViewController = [[ILPopoverController alloc] init];
        self.popover.contentSize           = (CGSize){320, 480};
    }
}

- (void)menuletClicked:(NSView*)view {
    NSLog(@"Menulet clicked");

    self.active = !self.active;

    if (self.active) {
        [self _setupPopover];
        [self.popover showRelativeToRect: view.frame
                                  ofView: view
                           preferredEdge: NSMinYEdge];
    }
    else {
        [self.popover performClose: self];
    }
}

@end
