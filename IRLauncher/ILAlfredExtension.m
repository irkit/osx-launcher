//
//  ILAlfredExtension.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/07/08.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAlfredExtension.h"

@implementation ILAlfredExtension

- (NSString*) title {
    return @"Alfred 2";
}

- (NSString*) installInformativeText {
    return @"I will launch \"Send IR signal.alfredworkflow\"";
}

- (void) install {
    NSBundle *bundle             = [NSBundle mainBundle];
    NSString *extensionInstaller = [bundle pathForResource: @"Send IR signal" ofType: @"alfredworkflow"];
    [[NSWorkspace sharedWorkspace] openFile: extensionInstaller];
}

@end
