//
//  ILSignalNameEditViewController
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IRSignal.h"

@protocol ILSignalNameEditViewControllerDelegate;

@interface ILSignalNameEditViewController : NSViewController

@property (nonatomic, weak) id<ILSignalNameEditViewControllerDelegate> delegate;
@property (nonatomic, strong) IRSignal *signal;

@property (nonatomic, weak) IBOutlet NSTextField *textField;
@property (nonatomic, weak) IBOutlet NSButton *saveButton;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;

@end

@protocol ILSignalNameEditViewControllerDelegate <NSObject>

@required
- (void)signalNameEditViewController:(ILSignalNameEditViewController*)c
                   didFinishWithInfo:(NSDictionary*)info;

@end
