//
//  ILNewSignalWindowController.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/06.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRKit.h"

@protocol ILNewSignalWindowControllerDelegate;

@interface ILNewSignalWindowController : NSWindowController<NSWindowDelegate>

@property (nonatomic, weak) id<ILNewSignalWindowControllerDelegate> signalDelegate;

@end

@protocol ILNewSignalWindowControllerDelegate <NSObject>

- (void) newSignalWindowController:(ILNewSignalWindowController*)c didFinishWithSignal:(IRSignal*)signal;

@end
