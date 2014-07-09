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

- (NSString*) uninstallInformativeText {
    return @"I will launch Alfred Preferences window for you, please uninstall \"Send IR signal\" workflow by yourself";
}

- (void) install {
    NSBundle *bundle             = [NSBundle mainBundle];
    NSString *extensionInstaller = [bundle pathForResource: @"Send IR signal" ofType: @"alfredworkflow"];
    [[NSWorkspace sharedWorkspace] openFile: extensionInstaller];
}

- (void) uninstall {
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier: @"com.runningwithcrayons.Alfred-Preferences"
                                                         options: NSWorkspaceLaunchDefault
                                  additionalEventParamDescriptor: NULL
                                                launchIdentifier: NULL];
}

- (BOOL) installed {
    // Check workflow directories under "~/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows/" and find one with our bundleid
    return NO;
}

@end
