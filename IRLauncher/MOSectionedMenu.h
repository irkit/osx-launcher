//
//  MOSectionedMenu.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MOIndexPath : NSObject

+ (MOIndexPath*)indexPathForItem:(NSUInteger)item inSection:(NSUInteger)section;

@property (nonatomic) NSInteger section;
@property (nonatomic) NSInteger item;

@end

@protocol MOSectionedMenuDataSource;

@interface MOSectionedMenu : NSObject<NSMenuDelegate>

@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) id<MOSectionedMenuDataSource> dataSource;

/// Defaults to YES
@property (nonatomic) BOOL separated;

/// MOSectionedMenu sets it's own menu.delegate to itself.
/// Set menuDelegate if you want to be called too.
@property (nonatomic, weak) id<NSMenuDelegate> menuDelegate;

@end

@protocol MOSectionedMenuDataSource <NSObject>

- (NSUInteger)numberOfSectionsInSectionedMenu:(MOSectionedMenu*)menu;
- (BOOL)sectionedMenu:(MOSectionedMenu*)menu hasHeaderForSection:(NSUInteger)sectionIndex;
- (BOOL)sectionedMenu:(MOSectionedMenu*)menu hasFooterForSection:(NSUInteger)sectionIndex;
- (NSUInteger)sectionedMenu:(MOSectionedMenu*)menu numberOfItemsInSection:(NSUInteger)sectionIndex;
- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu itemForIndexPath:(MOIndexPath*)indexPath;
- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu headerItemForSection:(NSUInteger)sectionIndex;
- (NSMenuItem*)sectionedMenu:(MOSectionedMenu*)menu footerItemForSection:(NSUInteger)sectionIndex;

@end