//
//  ILUSBConnectedPeripheral.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/07.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILUSBConnectedPeripheral : NSObject

@property (nonatomic,copy) NSString *dialinDevice;
@property (nonatomic) NSNumber *locationId;

@end
