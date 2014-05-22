//
//  ILSender.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/22.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILSender : NSObject

- (void)sendFileAtPath: (NSString*)filePath completion: (void (^)(NSError*))completion;

@end
