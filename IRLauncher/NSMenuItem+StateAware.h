//
//  NSMenuItem+StateAware.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/05.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSMenuItem (StateAware)

@property (nonatomic,copy) NSString *onTitle;
@property (nonatomic,copy) NSString *offTitle;

@end
