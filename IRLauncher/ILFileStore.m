//
//  ILSignalsDirectoryStore.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/15.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILFileStore.h"
#import "IRPeripheral.h"

#define ILLOG_DISABLED 1

#import "ILLog.h"
#import "ILConst.h"

static NSString * const kILConfigDirectory     = @".irkit.d/";
static NSString * const kILSignalsSubDirectory = @"signals/";

@interface ILFileStore ()

@property (nonatomic) NSMutableDictionary *entity;

@end

@implementation ILFileStore

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    NSData *data   = [NSData dataWithContentsOfFile: [ILFileStore configFile]];
    NSError *error = nil;
    if (data) {
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData: data options: 0 error: &error];
        if (!error && [jsonObject isKindOfClass: [NSDictionary class]]) {
            _entity = [jsonObject mutableCopy];
        }
        else {
            // TODO error handling, user might have edited the file manually and made it a invalid JSON file
        }
    }
    if (!_entity) {
        _entity = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)storeObject:(id)object forKey:(NSString *)key {
    ILLOG_CURRENT_METHOD;

    [_entity setObject: object forKey: key];
}

- (void)storePeripherals:(NSDictionary *)object {
    ILLOG_CURRENT_METHOD;

    NSMutableDictionary *peripherals = @{}.mutableCopy;
    [object enumerateKeysAndObjectsUsingBlock:^(NSString *key, IRPeripheral *obj, BOOL *stop) {
        peripherals[ key.lowercaseString ] = obj.asDictionary;
    }];
    [_entity setObject: peripherals forKey: @"peripherals"];
}

- (id)objectForKey:(NSString *)key {
    ILLOG_CURRENT_METHOD;

    return [_entity objectForKey: key];
}

- (NSDictionary*)loadPeripherals {
    ILLOG_CURRENT_METHOD;

    NSDictionary *peripheralForName  = [self objectForKey: @"peripherals"];
    NSMutableDictionary *peripherals = @{}.mutableCopy;
    [peripheralForName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        IRPeripheral *peripheral = [[IRPeripheral alloc] init];
        [peripheral inflateFromDictionary: obj];
        if (!peripheral.hostname) {
            // TODO show error?
            return;
        }
        peripherals[ peripheral.hostname.lowercaseString ] = peripheral;
    }];
    return peripherals;
}

- (void)synchronize {
    ILLOG_CURRENT_METHOD;

    NSError *error;
    NSData *json = [NSJSONSerialization dataWithJSONObject: _entity options: 0 error: &error];
    BOOL success = [json writeToFile: [ILFileStore configFile] atomically: YES];
    if (!success) {
        // TODO
        ILLOG( @"failed to write to: %@", [ILFileStore configFile] );
    }
}

#pragma mark - Class methods

+ (NSString*) configFile {
    return [[self configDirectory] stringByAppendingString: @"config.json"];
}

+ (NSString*) configDirectory {
    return [NSHomeDirectory() stringByAppendingFormat: @"/%@", kILConfigDirectory];
}

+ (NSString*) signalsDirectory {
    return [[self configDirectory] stringByAppendingString: kILSignalsSubDirectory];
}

@end
