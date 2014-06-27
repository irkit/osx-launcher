//
//  IRSignals+FileStore.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/27.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IRSignals+FileStore.h"
#import "ILSignalsDirectorySearcher.h"

@implementation IRSignals (FileStore)

- (void) loadFromFilesUnderDirectory: (NSString*)signalsDirectory completion:(void (^)(NSError *error))completion {
    [ILSignalsDirectorySearcher findSignalsUnderDirectory: [NSURL fileURLWithPath: signalsDirectory]
                                               completion: ^(NSArray *foundSignals, NSError *error) {
        if (error) {
            completion(error);
            return;
        }

        [foundSignals enumerateObjectsUsingBlock: ^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
                IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
                if (!signal.peripheral) {
                    // skip signals without hostname
                    // TODO somehow indicate that we skipped?
                    return;
                }
                [self addSignalsObject: signal];
            }];
        completion(nil);
    }];
}

@end
