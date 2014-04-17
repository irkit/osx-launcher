//
//  ILMenuButtonView.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ILMenuButtonViewDelegate;

@interface ILMenuButtonView : NSView

@property (nonatomic, weak) IBOutlet NSButton *button;
@property (nonatomic, weak) IBOutlet NSTextField *textField;
@property (nonatomic, weak) id <ILMenuButtonViewDelegate> delegate;

- (IBAction)pressed:(id)sender;

@end

@protocol ILMenuButtonViewDelegate <NSObject>

@required
- (void)menuButtonView:(ILMenuButtonView*)view didPress:(id)sender;

@end