//
//  ILSender.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/22.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILSender.h"
#import "ILLog.h"
#import "IRSignal.h"
#import "ILConst.h"
#import "IRKit.h"
#import "IRHTTPClient.h"

@implementation ILSender

- (void)sendFileAtPathAndAlertOnError:(NSString*)filePath {
    NSError *error;
    IRSignal *signal = [self signalFromFile: filePath error: &error];
    if (error) {
        NSString *message;
        switch (error.code) {
        case IRLauncherErrorCodeNotFound:
            message = nil;
            break;
        case IRLauncherErrorCodeInvalidFile:
            message = [NSString stringWithFormat: @"Failed to load file: %@", filePath];
            break;
        case IRLauncherErrorCodeUnsupported:
            message = @"Unsupported file format";
            break;
        default:
            message = [NSString stringWithFormat: NSLocalizedString( @"Failed to send file: %@ with error: %@", @"ILSender default error message" ), filePath, error.localizedDescription];
            break;
        }
        if (!message) {
            // MacOS might give some random (ex: -psn_0_xxxxx) argument on launch, silently ignore that
            return;
        }
        [self showAlertWithMessage: message];
        return;
    }
    [self sendSignalAndAlertOnError: signal];
}

- (void)sendSignalAndAlertOnError:(IRSignal*)signal {
    if (!signal.peripheral) {
        [self showAlertWithMessage: @"IRKit not found with provided \"hostname\" key. From which IRKit you want to send this signal?"];
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName: kILWillSendSignalNotification
                                                        object: self
                                                      userInfo: @{ @"signal": signal }];

    [signal sendWithCompletion:^(NSError *error) {
        if (error) {
            NSString *message = [NSString stringWithFormat: NSLocalizedString(@"Failed to send: %@ with error: %@", @"ILSender send error message"), signal.name, error.localizedDescription];
            [self showAlertWithMessage: message];
        }
    }];
}

#pragma mark - Private

- (IRSignal*)signalFromFile: (NSString*)filePath error:(NSError **)error {
    ILLOG( @"filePath: %@", filePath );

    if (![[NSFileManager defaultManager] fileExistsAtPath: filePath]) {
        *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                     code: IRLauncherErrorCodeNotFound
                                 userInfo: nil];
        return nil;
    }
    NSData *signalJSON = [NSData dataWithContentsOfFile: filePath];
    NSError *jsonError = nil;
    id signalObject    = [NSJSONSerialization JSONObjectWithData: signalJSON
                                                         options: 0
                                                           error: &jsonError];
    if (jsonError) {
        *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                     code: IRLauncherErrorCodeInvalidFile
                                 userInfo: nil];
        return nil;
    }
    if ([signalObject isKindOfClass: [NSDictionary class]]) {
        return [[IRSignal alloc] initWithDictionary: signalObject];
    }

    *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                 code: IRLauncherErrorCodeUnsupported
                             userInfo: nil];
    return nil;
}

- (void) showAlertWithMessage: (NSString*)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"];
    [alert setMessageText: message];
    [alert setAlertStyle: NSWarningAlertStyle];
    [alert runModal];
}

@end
