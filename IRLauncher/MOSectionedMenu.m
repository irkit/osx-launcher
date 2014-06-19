//
//  MOSectionedMenu.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "MOSectionedMenu.h"
#import "ILLog.h"

@interface MOSectionedMenu ()

@property (nonatomic) BOOL initialized;

@end

@implementation MOSectionedMenu

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    _menu          = [[NSMenu alloc] init];
    _menu.delegate = self;

    _separated = YES;

    return self;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
}

#pragma mark - NSMenuDelegate methods

- (void) menuNeedsUpdate:(NSMenu *)menu {
    if (_initialized) {
        return;
    }
    _initialized = YES;

    NSUInteger numberOfSections =[self.dataSource numberOfSectionsInSectionedMenu: self];
    for (NSUInteger section=0; section<numberOfSections; section++) {
        if ([self.dataSource respondsToSelector: @selector(sectionedMenu:hasHeaderForSection:)] &&
            [self.dataSource sectionedMenu: self hasHeaderForSection: section]) {
            NSMenuItem *item = [self.dataSource sectionedMenu: self headerItemForSection: section];
            [_menu addItem: item];
        }
        for (NSUInteger item=0; item<[self.dataSource sectionedMenu: self numberOfItemsInSection: section]; item++) {
            MOIndexPath *p   = [MOIndexPath indexPathForItem: item inSection: section];
            NSMenuItem *item = [self.dataSource sectionedMenu: self itemForIndexPath: p];
            [_menu addItem: item];
        }
        if ([self.dataSource respondsToSelector: @selector(sectionedMenu:hasFooterForSection:)] &&
            [self.dataSource sectionedMenu: self hasFooterForSection: section]) {
            NSMenuItem *item = [self.dataSource sectionedMenu: self footerItemForSection: section];
            [_menu addItem: item];
        }

        if (_separated && (section != numberOfSections)) {
            NSMenuItem *item = [NSMenuItem separatorItem];
            [_menu addItem: item];
        }
    }
}

@end

@implementation MOIndexPath

+ (MOIndexPath*)indexPathForItem:(NSUInteger)item inSection:(NSUInteger)section {
    MOIndexPath *ret = [[MOIndexPath alloc] init];
    ret.section = section;
    ret.item    = item;
    return ret;
}

@end
