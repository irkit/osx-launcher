//
//  MOSectionedMenu.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "MOSectionedMenu.h"
#import "ILLog.h"

NSString * const kMOSectionedMenuItemAdded         = @"kMOSectionedMenuItemAdded";
NSString * const kMOSectionedMenuItemUpdated       = @"kMOSectionedMenuItemUpdated";
NSString * const kMOSectionedMenuItemHeaderUpdated = @"kMOSectionedMenuItemHeaderUpdated";
NSString * const kMOSectionedMenuItemSectionKey    = @"kMOSectionedMenuItemSectionKey";
NSString * const kMOSectionedMenuItemIndexPathKey  = @"kMOSectionedMenuItemIndexPathKey";

@interface MOSectionedMenu ()

@property (nonatomic) BOOL initialized;
@property (nonatomic) BOOL opened;

@property (nonatomic) id itemHeaderUpdatedObserver;
@property (nonatomic) id itemAddedObserver;
@property (nonatomic) id itemUpdatedObserver;

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
    [self removeObservers];
}

- (void) setDataSource:(id<MOSectionedMenuDataSource>)dataSource {
    if (_dataSource) {
        [self removeObservers];
    }

    _dataSource = dataSource;

    if (!dataSource) {
        return;
    }

    __weak typeof(self) _self  = self;
    _itemHeaderUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName: kMOSectionedMenuItemHeaderUpdated
                                                                                   object: dataSource
                                                                                    queue: nil
                                                                               usingBlock:^(NSNotification *note) {
        if (!_self.initialized) {
            // don't try to update menu if it's not initialized yet
            return;
        }

        NSUInteger section = [note.userInfo[ kMOSectionedMenuItemSectionKey ] unsignedIntegerValue];
        if ([_self.dataSource respondsToSelector: @selector(sectionedMenu:updateHeaderItem:inSection:)]) {
            NSMenuItem *header = [self headerItemForSection: section];
            [_self.dataSource sectionedMenu: _self
                           updateHeaderItem: header
                                  inSection: section];
        }
    }];
    _itemAddedObserver = [[NSNotificationCenter defaultCenter] addObserverForName: kMOSectionedMenuItemAdded
                                                                           object: dataSource
                                                                            queue: nil
                                                                       usingBlock:^(NSNotification *note) {
        if (!_self.initialized) {
            // don't try to update menu if it's not initialized yet
            return;
        }

        MOIndexPath *indexPath = note.userInfo[ kMOSectionedMenuItemIndexPathKey ];
        NSMenuItem *item = [_self.dataSource sectionedMenu: _self
                                          itemForIndexPath: indexPath ];
        NSUInteger index = [self indexOfItemAtIndexPath: indexPath];
        [_self.menu insertItem: item
                       atIndex: index];
    }];
    _itemUpdatedObserver = [[NSNotificationCenter defaultCenter] addObserverForName: kMOSectionedMenuItemUpdated
                                                                             object: dataSource
                                                                              queue: nil
                                                                         usingBlock:^(NSNotification *note) {
        if (!_self.initialized) {
            // don't try to update menu if it's not initialized yet
            return;
        }

        MOIndexPath *indexPath = note.userInfo[ kMOSectionedMenuItemIndexPathKey ];
        NSMenuItem *item = [self itemAtIndexPath: indexPath];
        [_self.dataSource sectionedMenu: _self
                             updateItem: item
                            atIndexPath: indexPath];
    }];
}

- (NSMenuItem*) headerItemForSection:(NSUInteger)section {
    if (!_initialized) {
        [self menuNeedsUpdate: _menu];
    }

    NSUInteger index = [self indexOfHeaderForSection: section];
    return [_menu itemAtIndex: index];
}

- (NSUInteger) indexOfHeaderForSection:(NSUInteger)section {
    NSUInteger index = 0;

    NSUInteger numberOfSections =[self.dataSource numberOfSectionsInSectionedMenu: self];
    for (NSUInteger s=0; s<numberOfSections; s++) {
        if (s==section) {
            return index;
        }

        if ([self.dataSource respondsToSelector: @selector(sectionedMenu:hasHeaderForSection:)] &&
            [self.dataSource sectionedMenu: self hasHeaderForSection: s]) {
            index++;
        }

        index += [self.dataSource sectionedMenu: self numberOfItemsInSection: s];

        if ([self.dataSource respondsToSelector: @selector(sectionedMenu:hasFooterForSection:)] &&
            [self.dataSource sectionedMenu: self hasFooterForSection: s]) {
            index++;
        }

        if (_separated) {
            index++;
        }
    }
    NSAssert( 0, @"can't come here" );
    return 0;
}

- (NSMenuItem*) itemAtIndexPath:(MOIndexPath*)indexPath {
    if (!_initialized) {
        [self menuNeedsUpdate: _menu];
    }

    NSUInteger index = [self indexOfItemAtIndexPath: indexPath];
    return [_menu itemAtIndex: index];
}

- (NSUInteger) indexOfItemAtIndexPath:(MOIndexPath*)indexPath {
    NSUInteger index = 0;

    NSUInteger numberOfSections =[self.dataSource numberOfSectionsInSectionedMenu: self];
    for (NSUInteger s=0; s<numberOfSections; s++) {
        if ([self.dataSource respondsToSelector: @selector(sectionedMenu:hasHeaderForSection:)] &&
            [self.dataSource sectionedMenu: self hasHeaderForSection: s]) {
            index++;
        }

        if (indexPath.section == s) {
            index += indexPath.item;
            return index;
        }
        index += [self.dataSource sectionedMenu: self numberOfItemsInSection: s];

        if ([self.dataSource respondsToSelector: @selector(sectionedMenu:hasFooterForSection:)] &&
            [self.dataSource sectionedMenu: self hasFooterForSection: s]) {
            index++;
        }

        if (_separated) {
            index++;
        }
    }
    NSAssert( 0, @"can't come here" );
    return 0;
}

#pragma mark - Private

- (void) removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver: _itemHeaderUpdatedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver: _itemAddedObserver];
    [[NSNotificationCenter defaultCenter] removeObserver: _itemUpdatedObserver];
}

#pragma mark - NSMenuDelegate methods

- (void) menuNeedsUpdate:(NSMenu *)menu {
    ILLOG_CURRENT_METHOD;
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

- (void) menuWillOpen:(NSMenu *)menu {
    _opened = YES;
    if ([self.dataSource respondsToSelector: @selector(menuWillOpen:)]) {
        [self.dataSource menuWillOpen: menu];
    }
}

- (void) menuDidClose:(NSMenu *)menu {
    _opened = NO;
    if ([self.dataSource respondsToSelector: @selector(menuDidClose:)]) {
        [self.dataSource menuDidClose: menu];
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
