//
//  ILMenu.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenu.h"
#import "ILAppDelegate.h"

const NSInteger kTagSignals     = 10;
const NSInteger kTagPeripherals = 20;

@interface ILMenu ()

@property (nonatomic) NSMutableArray *signals;
@property (nonatomic) NSMutableArray *peripherals;

@end

@implementation ILMenu

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    return self;
}

- (void)setSignalHeaderTitle:(NSString*)text {
    NSMenuItem *item = [self itemWithTag: kTagSignals];
    item.title = text;
}

- (void)setPeripheralHeaderTitle:(NSString*)text {
    NSMenuItem *item = [self itemWithTag: kTagPeripherals];
    item.title = text;
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

@end
