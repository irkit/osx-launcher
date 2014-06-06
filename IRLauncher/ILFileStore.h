//
//  ILSignalsDirectoryStore.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/15.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRPersistentStore.h"
#import "IRSignal.h"

/// Saves key-value data structure under ~/.irkit.d/
@interface ILFileStore : NSObject<IRPersistentStore>

- (void)storeObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)synchronize;

+ (NSString*) configFile;
+ (NSString*) configDirectory;
+ (NSString*) signalsDirectory;
+ (BOOL) saveSignal: (IRSignal*) signal;

@end
