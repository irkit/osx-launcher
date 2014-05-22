//
//  ILMenu.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenu.h"

#define ILLOG_DISABLED 1

#import "ILLog.h"
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
@property (nonatomic) NSMutableArray *usbMenuItems;
@property (nonatomic) BOOL isVisible;

@end

@implementation ILMenu

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    ILLOG_CURRENT_METHOD;
    self = [super initWithCoder: aDecoder];
    if (!self) { return nil; }

    self.delegate = self;

    _signalMenuItems     = @[].mutableCopy;
    _peripheralMenuItems = @[].mutableCopy;
    _usbMenuItems        = @[].mutableCopy;

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

- (void)setQuicksilverIntegrationTitle:(NSString*)title
                        alternateTitle:(NSString*)alternateTitle
                           buttonTitle:(NSString*)buttonTitle
                  alternateButtonTitle:(NSString*)alternateButtonTitle
                                action:(void (^)(id sender, NSCellStateValue value))action {
    NSMenuItem *quicksilverIntegration = [self itemWithTag: kTagQuicksilverIntegration];
    ILMenuButtonView *view             = (ILMenuButtonView*)quicksilverIntegration.view;
    if (![view isKindOfClass: [ILMenuButtonView class]]) {
        view                        = [ILUtils loadClassFromNib: [ILMenuButtonView class]];
        quicksilverIntegration.view = view;
    }

    [view setTitle: title
           alternateTitle: alternateTitle
              buttonTitle: buttonTitle
     alternateButtonTitle: alternateButtonTitle
                   action: action];
}

- (void)setQuicksilverIntegrationButtonState:(NSCellStateValue)state {
    NSMenuItem *quicksilverIntegration = [self itemWithTag: kTagQuicksilverIntegration];
    ILMenuButtonView *view             = (ILMenuButtonView*)quicksilverIntegration.view;
    view.state = state;
}

- (void)setStartAtLoginTitle:(NSString*)title
              alternateTitle:(NSString*)alternateTitle
                      action:(void (^)(id sender, NSCellStateValue value))action {
    NSMenuItem *startAtLogin = [self itemWithTag: kTagStartAtLoginCheckbox];
    ILMenuCheckboxView *view = (ILMenuCheckboxView*)startAtLogin.view;
    if (![view isKindOfClass: [ILMenuCheckboxView class]]) {
        view              =[ILUtils loadClassFromNib: [ILMenuCheckboxView class]];
        startAtLogin.view = view;
    }

    [view setTitle: title
     alternateTitle: alternateTitle
             action: action];
}

- (void)setStartAtLoginState:(NSCellStateValue)state {
    NSMenuItem *startAtLogin = [self itemWithTag: kTagStartAtLoginCheckbox];
    ILMenuCheckboxView *view = (ILMenuCheckboxView*)startAtLogin.view;
    view.state = state;
}

- (void)addSignalMenuItem:(NSMenuItem *)item {
    ILLOG( @"item: %@", item );

    [_signalMenuItems addObject: item];

    NSUInteger index = [self indexOfItemWithTag: kTagSignals];
    [self insertItem: item atIndex: index + self.numberOfSignalMenuItems];
}

- (void)addPeripheralMenuItem:(NSMenuItem *)item {
    ILLOG( @"item: %@", item );

    [_peripheralMenuItems addObject: item];

    NSUInteger index = [self indexOfItemWithTag: kTagPeripherals];
    [self insertItem: item atIndex: index + self.numberOfPeripheralMenuItems];
}

- (void)addUSBMenuItem:(NSMenuItem *)item {
    ILLOG( @"item: %@", item );

    [_usbMenuItems addObject: item];
    NSUInteger index = [self indexOfItemWithTag: kTagUSB];
    [self insertItem: item atIndex: index + self.numberOfUSBMenuItems];
}

- (void)removeUSBMenuItemAtIndex: (NSUInteger)index {
    NSMenuItem *item = self.usbMenuItems[ index ];
    if (!item) {
        return;
    }

    [self.usbMenuItems removeObject: item];
    [self removeItem: item];
}

#pragma mark - Private

- (NSUInteger)numberOfSignalMenuItems {
    return _signalMenuItems.count;
}

- (NSUInteger)numberOfPeripheralMenuItems {
    return _peripheralMenuItems.count;
}

- (NSUInteger)numberOfUSBMenuItems {
    return _usbMenuItems.count;
}

- (void) setHeaderTitleWithTag: (NSUInteger)tag title:(NSString*)title animating:(BOOL)animating {
    NSMenuItem *item = [self itemWithTag: tag];
    if (![item.view isKindOfClass: [ILMenuProgressView class]]) {
        item.view = [ILUtils loadClassFromNib: [ILMenuProgressView class]];
    }
    ILMenuProgressView *view = (ILMenuProgressView*)item.view;
    view.animating = animating;
    if (self.isVisible) {
        [view startAnimationIfNeeded];
    }
    [view.textField setStringValue: title];
}

#pragma mark - NSMenuDelegate

- (void) menuWillOpen:(NSMenu *)menu {
    self.isVisible = YES;

    NSArray *items = @[ [self itemWithTag: kTagSignals], [self itemWithTag: kTagPeripherals],[self itemWithTag: kTagUSB]];
    [items enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [(ILMenuProgressView*)item.view startAnimationIfNeeded];
    }];

    [self.menuDelegate menuWillOpen: self];
}

- (void) menuDidClose:(NSMenu *)menu {
    self.isVisible = NO;

    NSArray *items = @[ [self itemWithTag: kTagSignals], [self itemWithTag: kTagPeripherals],[self itemWithTag: kTagUSB]];
    [items enumerateObjectsUsingBlock:^(NSMenuItem *item, NSUInteger idx, BOOL *stop) {
        [(ILMenuProgressView*)item.view stopAnimation];
    }];

    [self.menuDelegate menuDidClose: self];
}

@end
