//
//  NSString+UUID.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/12.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "NSString+UUID.h"

@implementation NSString (UUID)

+ (NSString *)uniqueString {
    CFUUIDRef uuid      = CFUUIDCreate(NULL);
    CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (__bridge_transfer NSString *)uuidStr;
}

@end
