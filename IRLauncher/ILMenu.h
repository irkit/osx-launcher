//
//  ILMenu.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSInteger kTagSignals;
extern const NSInteger kTagLearnSignal;
extern const NSInteger kTagPeripherals;
extern const NSInteger kTagStartAtLoginCheckbox;
extern const NSInteger kTagQuicksilverIntegration;

@protocol ILMenuDelegate;

@interface ILMenu : NSMenu<NSMenuDelegate>

@property (nonatomic, weak) id<ILMenuDelegate> menuDelegate;

- (void)setSignalHeaderTitle:(NSString*)title animating:(BOOL)animating;
- (void)setPeripheralHeaderTitle:(NSString*)title animating:(BOOL)animating;

- (void)addSignalMenuItem: (NSMenuItem*)item;
- (void)addPeripheralMenuItem: (NSMenuItem*)item;

@end

@protocol ILMenuDelegate <NSObject>

@required
- (void) menuWillOpen: (ILMenu*)menu;
- (void) menuDidClose: (ILMenu*)menu;

@end

