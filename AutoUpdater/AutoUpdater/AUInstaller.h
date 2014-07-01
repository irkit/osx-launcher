//
//  AUInstaller.h
//  AutoUpdater
//
//  Created by Masakazu Ohtsuka on 2014/07/01.
//  Copyright (c) 2014年 maaash.jp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AUInstaller : NSObject

- (instancetype) initWithDestinationPath:(NSString*)destinationPath
                              sourcePath:(NSString*)sourcePath;
- (void) installWithCompletion: (void (^)(NSError *error))completion;

@end
