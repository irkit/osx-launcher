//
//  ILSignalsDirectoryStore.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/15.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILFileStore.h"

#define ILLOG_DISABLED 1

#import "ILLog.h"

@implementation ILFileStore

- (void)storeObject:(id)object forKey:(NSString *)key {
    ILLOG_CURRENT_METHOD;

//    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
//    [d setObject: object
//          forKey: [NSString stringWithFormat: @"%@:%@",
//                   IR_NSUSERDEFAULTS_PREFIX, key]];
}

- (id)objectForKey:(NSString *)key {
    ILLOG_CURRENT_METHOD;

//    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
//    return [d objectForKey: [NSString stringWithFormat: @"%@:%@",
//                             IR_NSUSERDEFAULTS_PREFIX, key]];
    return nil;
}

- (void)synchronize {
    ILLOG_CURRENT_METHOD;
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
