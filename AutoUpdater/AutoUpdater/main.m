//
//  main.m
//  AutoUpdater
//
//  Created by Masakazu Ohtsuka on 2014/07/01.
//  Copyright (c) 2014年 maaash.jp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AUTerminationObserver.h"
#import "AUInstaller.h"

void showModalAlertWithMessage(NSString *message);

/// How to call:
/// NSString *relaunchToolPath = [[relaunchPath stringByAppendingPathComponent: @"/Contents/MacOS"] stringByAppendingPathComponent: finishInstallToolName];
/// [NSTask launchedTaskWithLaunchPath: relaunchToolPath arguments:@[[host bundleIdentifier],
///                                                                  [host bundlePath],
///                                                                  tempDir]];
int main(int argc, const char * argv[]){
    if (argc <= 4) {
        return EXIT_FAILURE;
    }

    @autoreleasepool {
        NSString *bundleIdentifier = [NSString stringWithCString: argv[1] encoding: NSUTF8StringEncoding];
        NSString *destination      = [NSString stringWithCString: argv[2] encoding: NSUTF8StringEncoding];
        NSString *source           = [NSString stringWithCString: argv[3] encoding: NSUTF8StringEncoding];
        NSString *appname          = [destination lastPathComponent];

        AUTerminationObserver *observer = [[AUTerminationObserver alloc] init];
        observer.timeout = 10.;
        [observer observeTerminationOfBundleIdentifier: bundleIdentifier completion:^(NSError* error) {
            if (error) {
                showModalAlertWithMessage([NSString stringWithFormat: @"Failed to terminate %@", appname]);
                exit(EXIT_FAILURE);
            }
            AUInstaller *installer = [[AUInstaller alloc] initWithDestinationPath: destination
                                                                       sourcePath: source];
            [installer installWithCompletion:^(NSError* error) {
                    if (error) {
                        showModalAlertWithMessage([NSString stringWithFormat: @"Failed to install update of %@", appname]);
                        exit(EXIT_FAILURE);
                    }
                    NSError *launchError = nil;
                    NSArray *arguments = @[ @"--autoupdated" ];
                    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] launchApplicationAtURL: [NSURL fileURLWithPath: destination]
                                                                                              options: NSWorkspaceLaunchDefault
                                                                                        configuration: @{ NSWorkspaceLaunchConfigurationArguments: arguments }
                                                                                                error: &launchError];
                    if (!app || launchError) {
                        showModalAlertWithMessage([NSString stringWithFormat: @"Failed to relaunch %@", appname]);
                        exit(EXIT_FAILURE);
                    }

                    // TODO should we wait for a while to confirm that app is really successfully launched?

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[NSFileManager defaultManager] removeItemAtPath: source error: NULL];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                    exit(EXIT_SUCCESS);
                                });
                        });
                }];
        }];
        [[NSApplication sharedApplication] run];
    }

    return EXIT_SUCCESS;
}

void showModalAlertWithMessage(NSString *message) {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"];
    [alert setMessageText: message];
    [alert setAlertStyle: NSWarningAlertStyle];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    [alert runModal];
}
