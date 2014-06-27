//
//  IRSignals+FileStore.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/27.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IRSignals.h"

@interface IRSignals (FileStore)

- (void) loadFromFilesUnderDirectory: (NSString*)signalsDirectory completion:(void (^)(NSError *error))completion;

@end
