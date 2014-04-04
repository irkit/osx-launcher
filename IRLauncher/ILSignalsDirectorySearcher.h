//
//  ILSignalsDirectorySearcher.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/04.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILSignalsDirectorySearcher : NSObject

+ (void) findSignalsUnderDirectory: (NSURL*)signalsURL completion: (void (^)(NSArray *foundSignals)) completion;

@end
