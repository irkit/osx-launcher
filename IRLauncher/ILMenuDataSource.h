//
//  ILMenuDataSource.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOSectionedMenu.h"
#import "IRSearcher.h"
#import "ILLearnSignalWindowController.h"

@interface ILMenuDataSource : NSObject<
        MOSectionedMenuDataSource,
        IRSearcherDelegate,
        ILLearnSignalWindowControllerDelegate
        >

- (void) setSignals:(IRSignals *)signals;
- (void) searchForSignals;

@end
