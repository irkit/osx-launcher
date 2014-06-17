//
//  ILSignalReceiveViewController
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/06.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRKit.h"

@protocol ILSignalReceiveViewControllerDelegate;

@interface ILSignalReceiveViewController : NSViewController

@property (nonatomic, weak) id<ILSignalReceiveViewControllerDelegate> delegate;

@end

@protocol ILSignalReceiveViewControllerDelegate <NSObject>

- (void) signalReceiveViewController:(ILSignalReceiveViewController*)c didReceiveSignal:(IRSignal*)signal withError:(NSError*)error;

@end
