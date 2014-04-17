//
//  ILMenu.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenu.h"
#import "ILAppDelegate.h"
#import "ILMenuHeaderView.h"
#import "ILUtils.h"

const NSInteger kTagSignals     = 10;
const NSInteger kTagPeripherals = 20;
const NSInteger kTagUSB         = 30;

@interface ILMenu ()

@property (nonatomic) NSMutableArray *signals;
@property (nonatomic) NSMutableArray *peripherals;

@end

@implementation ILMenu

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (!self) { return nil; }

    self.delegate = self;

    return self;
}

- (void)setSignalHeaderTitle:(NSString*)title animating:(BOOL)animating {
    [self setHeaderTitleWithTag: kTagSignals title: title animating: animating];
}

- (void)setPeripheralHeaderTitle:(NSString*)title animating:(BOOL)animating {
    [self setHeaderTitleWithTag: kTagPeripherals title: title animating: animating];
}

- (void)setUSBHeaderTitle:(NSString*)title animating:(BOOL)animating {
    [self setHeaderTitleWithTag: kTagUSB title: title animating: animating];
}

- (void)addSignalMenuItem:(NSMenuItem *)item {
    ILLOG( @"item: %@", item );

    [_signals addObject: item];

    NSUInteger index = [self indexOfItemWithTag: kTagSignals];
    [self insertItem: item atIndex: index + self.numberOfSignalMenuItems + 1];
}

- (void)addPeripheralMenuItem:(NSMenuItem *)item {
    ILLOG( @"item: %@", item );

    [_peripherals addObject: item];

    NSUInteger index = [self indexOfItemWithTag: kTagPeripherals];
    [self insertItem: item atIndex: index + self.numberOfPeripheralMenuItems + 1];
}

- (NSUInteger)numberOfSignalMenuItems {
    return _signals.count;
}

- (NSUInteger)numberOfPeripheralMenuItems {
    return _peripherals.count;
}

#pragma mark - Private

- (void) setHeaderTitleWithTag: (NSUInteger)tag title:(NSString*)title animating:(BOOL)animating {
    NSMenuItem *item = [self itemWithTag: tag];
    if (![item.view isKindOfClass: [ILMenuHeaderView class]]) {
        item.view = [ILUtils loadClassFromNib: [ILMenuHeaderView class]];
    }
    ILMenuHeaderView *view = (ILMenuHeaderView*)item.view;
    view.animating = animating;
    [view.textField setStringValue: title];
}

#pragma mark - NSMenuDelegate

- (void) menuWillOpen:(NSMenu *)menu {
    ILLOG( @"size: %@", NSStringFromSize(menu.size));

    NSArray *items = @[ [self itemWithTag: kTagSignals], [self itemWithTag: kTagPeripherals],[self itemWithTag: kTagUSB]];
    [items enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [(ILMenuHeaderView*)item.view startAnimationIfNeeded];
//        NSRect frame = item.view.frame;
//        frame.size.width = menu.size.width;
//        item.view.frame = frame;
    }];
}

- (void) menuDidClose:(NSMenu *)menu {
    ILLOG_CURRENT_METHOD;
    NSArray *items = @[ [self itemWithTag: kTagSignals], [self itemWithTag: kTagPeripherals],[self itemWithTag: kTagUSB]];
    [items enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [(ILMenuHeaderView*)item.view stopAnimation];
    }];
}

@end
