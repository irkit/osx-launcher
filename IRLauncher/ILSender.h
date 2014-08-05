//
//  ILSender.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/22.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRSignal.h"

@interface ILSender : NSObject

- (void)sendFileAtPathAndAlertOnError:(NSString*)filePath;
- (void)sendSignalAndAlertOnError:(IRSignal*)signal;

@end
