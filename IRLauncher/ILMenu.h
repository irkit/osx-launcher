//
//  ILMenu.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILPeripheral.h"
#import "ILSignal.h"

@interface ILMenu : NSMenu

- (void) addPeripherals:(ILPeripheral*)peripheral;
- (void) addSignals:(ILSignal*)signal;

@end
