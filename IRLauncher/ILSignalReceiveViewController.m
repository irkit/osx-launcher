//
//  ILSignalReceiveViewController
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/06.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILSignalReceiveViewController.h"
#import "ILLog.h"
#import "IRHTTPClient.h"

@interface ILSignalReceiveViewController ()

@property (nonatomic,strong) IRHTTPClient *waiter;

@end

@implementation ILSignalReceiveViewController

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void)loadView {
    ILLOG_CURRENT_METHOD;
    [super loadView];

    [self.progressIndicator startAnimation: nil];

    NSArray *localizations       = [[NSBundle mainBundle] preferredLocalizations];
    NSMutableAttributedString *s = self.detailTextField.attributedStringValue.mutableCopy;
    // emphasize "shortly"
    if ([localizations[0] isEqualToString: @"ja"]) {
        [s setAttributes: @{ NSForegroundColorAttributeName: [NSColor redColor] } range: (NSRange){ 20,2 }];
    }
    else {
        [s setAttributes: @{ NSForegroundColorAttributeName: [NSColor redColor] } range: (NSRange){ 65,7 }];
    }
    self.detailTextField.attributedStringValue = s;

    __weak typeof(self) _self = self;
    _waiter                   = [IRHTTPClient waitForSignalWithCompletion:^(NSHTTPURLResponse *res, IRSignal *signal, NSError *error) {
        if (error) {
            ILLOG( @"error: %@", error );
            [_self.delegate signalReceiveViewController: _self didReceiveSignal: nil withError: error];
            return;
        }
        if (signal) {
            [_self.delegate signalReceiveViewController: _self didReceiveSignal: signal withError: nil];
        }
    }];
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
    [_waiter cancel];
}

- (void) didReceiveSignal: (IRSignal*)signal {
    ILLOG_CURRENT_METHOD;

    [_delegate signalReceiveViewController: self didReceiveSignal: signal withError: nil];
}

- (IBAction) debugButtonPressed: (id)sender {
    ILLOG_CURRENT_METHOD;
    [_delegate signalReceiveViewController: self didReceiveSignal: nil withError: nil];
}

@end
