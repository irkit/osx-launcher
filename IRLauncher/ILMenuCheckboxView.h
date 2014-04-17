//
//  ILMenuCheckboxView.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ILMenuCheckboxViewDelegate;

@interface ILMenuCheckboxView : NSView

@property (nonatomic, weak) IBOutlet NSButton *checkbox;
@property (nonatomic, weak) IBOutlet NSTextField *textField;
@property (nonatomic, weak) id <ILMenuCheckboxViewDelegate> delegate;

@end

@protocol ILMenuCheckboxViewDelegate <NSObject>

@required
- (void)menuCheckboxView:(ILMenuCheckboxView*)view didTouchCheckbox:(id)sender newValue:(BOOL)onoff;

@end