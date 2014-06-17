//
//  ILNewSignalWindowController.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ILSignalReceiveViewController.h"
#import "ILSignalNameEditViewController.h"
#import "IRSignal.h"

@protocol ILLearnSignalWindowControllerDelegate;

/// "Learn" consists of receiving a signal (ILSignalReceiveViewController)
/// and naming it (ILSignalNameEditViewController)
@interface ILLearnSignalWindowController : NSWindowController<NSWindowDelegate, ILSignalReceiveViewControllerDelegate, ILSignalNameEditViewControllerDelegate>

@property (nonatomic, weak) id<ILLearnSignalWindowControllerDelegate> signalDelegate;

@end

@protocol ILLearnSignalWindowControllerDelegate <NSObject>

@required
- (void)learnSignalWindowController:(ILLearnSignalWindowController*)c
                didFinishWithSignal:(IRSignal*)signal
                          withError:(NSError*)error;

@end
