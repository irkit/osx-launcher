//
//  MOApplicationUpdater.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/28.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "MOApplicationUpdater.h"

@interface MOApplicationUpdater ()

@property (nonatomic) NSURL *archiveURL;

@end

@implementation MOApplicationUpdater

- (instancetype) initWithArchiveURL: (NSURL*)archiveURL {
    self = [super init];
    if (!self) { return nil; }

    _archiveURL = archiveURL;

    return self;
}

- (void) run {
    NSTask *task = [[NSTask alloc] init];

    task.launchPath  = [[NSBundle mainBundle] pathForResource: @"install-update" ofType: @"sh"];
    task.arguments   = @[ [_archiveURL absoluteString], [NSBundle mainBundle].bundlePath ];
    task.environment = [[NSProcessInfo processInfo].environment dictionaryWithValuesForKeys: @[@"PATH", @"USER", @"HOME", @"SHELL"]];

    [task launch];
}

@end
