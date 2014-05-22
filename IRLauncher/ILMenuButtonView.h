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
@property (nonatomic, copy) void (^action)(id sender, NSCellStateValue value);
@property (nonatomic) NSCellStateValue state;

- (void)        setTitle:(NSString*)title
          alternateTitle:(NSString*)alternateTitle
             buttonTitle:(NSString*)buttonTitle
    alternateButtonTitle:(NSString*)alternateButtonTitle
                  action:(void (^)(id sender, NSCellStateValue value))action;
- (IBAction)pressed:(id)sender;

@end

@protocol ILMenuButtonViewDelegate <NSObject>

@optional
- (void)menuButtonView:(ILMenuButtonView*)view didPress:(id)sender;

@end