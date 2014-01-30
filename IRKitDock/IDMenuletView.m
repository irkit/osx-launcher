//
//  IDVersionChecker.m
//  IRKitDock
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IDMenuletView.h"

static void *kActiveChangedKVO = &kActiveChangedKVO;

@implementation IDMenuletView

- (void)drawRect:(NSRect)rect
{
    NSImage *menuletIcon;
    [[NSColor clearColor] set];   
    if ([self.controller isActive]) {
        menuletIcon = [NSImage imageNamed:@"Moon_Full.png"];
    } else {
        menuletIcon = [NSImage imageNamed:@"Moon_New.png"];
    }
    [menuletIcon drawInRect:NSInsetRect(rect, 2, 2)
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1.0];
}

- (void)mouseDown:(NSEvent *)event {
    NSLog(@"Mouse down event: %@", event);
    [self.controller menuletClicked:self];
}

@end
