//
//  IDVersionChecker.m
//  IRKitDock
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IDMenuletView.h"

@implementation IDMenuletView

- (void)drawRect:(NSRect)rect {
    [[NSColor clearColor] set];
    NSImage *menuletIcon = [NSImage imageNamed:@"icn_device@2x.png"];
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
