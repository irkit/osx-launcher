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

@implementation ILSender

- (void)sendFileAtPath: (NSString*)filePath completion: (void (^)(NSError*))completion {
    ILLOG( @"filePath: %@", filePath );

    if (![[NSFileManager defaultManager] fileExistsAtPath: filePath]) {
        NSError *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                             code: IRLauncherErrorCodeInvalidFile
                                         userInfo: nil];
        completion(error);
        return;
    }
    NSData *signalJSON = [NSData dataWithContentsOfFile: filePath];
    NSError *error;
    id signalObject = [NSJSONSerialization JSONObjectWithData: signalJSON
                                                      options: 0
                                                        error: &error];
    if (error) {
        NSError *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                             code: IRLauncherErrorCodeInvalidFile
                                         userInfo: nil];
        completion(error);
        return;
    }
    if ([signalObject isKindOfClass: [NSDictionary class]]) {
        IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalObject];
        if (signal.peripheral) {

            [[NSNotificationCenter defaultCenter] postNotificationName: kILWillSendSignalNotification
                                                                object: self
                                                              userInfo: @{ @"signal": signal }];

            [signal sendWithCompletion:^(NSError *error) {
                ILLOG( @"sent with error: %@", error );
                completion(error);
            }];
        }
        else {
//            [self alertWithMessage: @"Set signal.peripheral"];
            completion(nil);

            // TODO
            // [signal ]
            // completion
        }
    }
    else if ([signalObject isKindOfClass: [NSArray class]]) {
        // TODO define a JSON representation of interval, and send multiple signals in a row?
        NSError *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                             code: IRLauncherErrorCodeUnsupported
                                         userInfo: nil];
        completion(error);
    }
}

@end
