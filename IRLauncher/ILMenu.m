//
//  ILMenu.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenu.h"
#import "ILMenuProgressView.h"
#import "ILMenuCheckboxView.h"
#import "ILMenuButtonView.h"
#import "ILUtils.h"

const NSInteger kTagSignals                = 10;
const NSInteger kTagPeripherals            = 20;
const NSInteger kTagUSB                    = 30;
const NSInteger kTagStartAtLoginCheckbox   = 40;
const NSInteger kTagQuicksilverIntegration = 50;

@interface ILMenu ()

@property (nonatomic) NSMutableArray *signalMenuItems;
@property (nonatomic) NSMutableArray *peripheralMenuItems;

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

    [_signalMenuItems addObject: item];

    NSUInteger index = [self indexOfItemWithTag: kTagSignals];
    [self insertItem: item atIndex: index + self.numberOfSignalMenuItems + 1];
}

- (void)addPeripheralMenuItem:(NSMenuItem *)item {
    ILLOG( @"item: %@", item );

    [_peripheralMenuItems addObject: item];

    NSUInteger index = [self indexOfItemWithTag: kTagPeripherals];
    [self insertItem: item atIndex: index + self.numberOfPeripheralMenuItems + 1];
}

- (NSUInteger)numberOfSignalMenuItems {
    return _signalMenuItems.count;
}

- (NSUInteger)numberOfPeripheralMenuItems {
    return _peripheralMenuItems.count;
}

#pragma mark - Private

- (void) setHeaderTitleWithTag: (NSUInteger)tag title:(NSString*)title animating:(BOOL)animating {
    NSMenuItem *item = [self itemWithTag: tag];
    if (![item.view isKindOfClass: [ILMenuProgressView class]]) {
        item.view = [ILUtils loadClassFromNib: [ILMenuProgressView class]];
    }
    ILMenuProgressView *view = (ILMenuProgressView*)item.view;
    view.animating = animating;
    [view.textField setStringValue: title];
}

#pragma mark - NSMenuDelegate

- (void) menuWillOpen:(NSMenu *)menu {
    ILLOG( @"size: %@", NSStringFromSize(menu.size));

    NSArray *items = @[ [self itemWithTag: kTagSignals], [self itemWithTag: kTagPeripherals],[self itemWithTag: kTagUSB]];
    [items enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [(ILMenuProgressView*)item.view startAnimationIfNeeded];
    }];

    NSMenuItem *startAtLogin = [self itemWithTag: kTagStartAtLoginCheckbox];
    if (![startAtLogin.view isKindOfClass: [ILMenuCheckboxView class]]) {
        ILMenuCheckboxView *view =[ILUtils loadClassFromNib: [ILMenuCheckboxView class]];
        view.delegate = self.checkboxDelegate;
        [view.textField setStringValue: @"Start at login"];
        startAtLogin.view = view;
    }

    NSMenuItem *quicksilverIntegration = [self itemWithTag: kTagQuicksilverIntegration];
    if (![quicksilverIntegration.view isKindOfClass: [ILMenuCheckboxView class]]) {
        ILMenuButtonView *view =[ILUtils loadClassFromNib: [ILMenuButtonView class]];
        view.delegate = self.buttonDelegate;
        [view.textField setStringValue: @"Quicksilver integration"];
        [view.button setStringValue: @"Install"];
        quicksilverIntegration.view = view;
    }

    [self.menuDelegate menuWillOpen: self];
}

- (void) menuDidClose:(NSMenu *)menu {
    ILLOG_CURRENT_METHOD;
    NSArray *items = @[ [self itemWithTag: kTagSignals], [self itemWithTag: kTagPeripherals],[self itemWithTag: kTagUSB]];
    [items enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [(ILMenuProgressView*)item.view stopAnimation];
    }];

    [self.menuDelegate menuDidClose: self];
}

@end
