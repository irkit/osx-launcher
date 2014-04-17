//
//  ILMenu.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILMenu : NSMenu<NSMenuDelegate>

- (void)setSignalHeaderTitle:(NSString*)title animating:(BOOL)animating;
- (void)setPeripheralHeaderTitle:(NSString*)title animating:(BOOL)animating;
- (void)setUSBHeaderTitle:(NSString*)title animating:(BOOL)animating;
- (void)addSignalMenuItem: (NSMenuItem*)item;
- (void)addPeripheralMenuItem: (NSMenuItem*)item;

@end
