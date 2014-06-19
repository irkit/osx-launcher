//
//  ILStatusItem.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILStatusItem.h"

@interface ILStatusItem ()

@property (nonatomic) NSStatusItem *statusItem;

@end

@implementation ILStatusItem

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 30.];
    [_statusItem setHighlightMode: YES];
    [_statusItem setImage: [NSImage imageNamed: @"StatusBarIcon_111"]]; // TODO
    [_statusItem setAlternateImage: [NSImage imageNamed: @"StatusBarIcon_111"]];

    return self;
}

- (void) setMenu:(NSMenu *)menu {
    _statusItem.menu = menu;
}

@end
