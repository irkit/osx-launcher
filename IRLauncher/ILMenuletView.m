//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuletView.h"

@implementation ILMenuletView

- (void)drawRect:(NSRect)rect {
    [[NSColor clearColor] set];
    NSImage *menuletIcon = [NSImage imageNamed: @"StatusBarIcon"];
    [menuletIcon drawInRect: NSInsetRect(rect, 2, 2)
                   fromRect: NSZeroRect
                  operation: NSCompositeSourceOver
                   fraction: 1.0];
}

- (void)mouseDown:(NSEvent *)event {
    ILLOG(@"Mouse down event: %@", event);
    [self.statusItem popUpStatusItemMenu: self.menu];
}

@end
