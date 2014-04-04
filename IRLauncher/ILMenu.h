//
//  ILMenu.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILMenu : NSMenu

- (void)setSignalHeaderTitle:(NSString*)text;
- (void)setPeripheralHeaderTitle:(NSString*)text;
- (void)setUSBHeaderTitle:(NSString*)text;
- (void)addSignalMenuItem: (NSMenuItem*)item;
- (void)addPeripheralMenuItem: (NSMenuItem*)item;

@end
