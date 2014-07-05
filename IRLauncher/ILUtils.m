//
//  ILUtils.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILUtils.h"
#import "ILLog.h"

@implementation ILUtils

+ (NSString*)chompedString: (NSString*)orig {
    return [orig stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (id)loadClassNamed: (NSString*)className {
    NSArray *nibEntries = @[];
    NSNib *nib          = [[NSNib alloc] initWithNibNamed: className bundle: [NSBundle mainBundle]];
    [nib instantiateWithOwner: nil topLevelObjects: &nibEntries];
    return [ILUtils firstObjectOf: nibEntries meetsBlock:^BOOL (id obj, NSUInteger idx) {
        if ([obj isKindOfClass: NSClassFromString(className)]) {
            return YES;
        }
        return NO;
    }];
}

+ (id)firstObjectOf:(NSArray *)array meetsBlock:(BOOL (^)(id obj, NSUInteger idx))block {
    __block id result = nil;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (block(obj,idx)) {
            result = obj;
            *stop = 1;
        }
    }];
    return result;
}

@end
