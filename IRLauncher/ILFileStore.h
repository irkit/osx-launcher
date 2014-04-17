//
//  ILSignalsDirectoryStore.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/15.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRPersistentStore.h"

@interface ILFileStore : NSObject<IRPersistentStore>

- (void)storeObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)synchronize;

@end
