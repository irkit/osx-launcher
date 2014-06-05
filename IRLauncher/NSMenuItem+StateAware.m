//
//  NSMenuItem+StateAware.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/05.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "NSMenuItem+StateAware.h"
#import <objc/runtime.h>

@interface NSMenuItem ()

@property (nonatomic) BOOL stateHookInstalled;

@end

@implementation NSMenuItem (StateAware)

- (BOOL)stateHookInstalled {
    return [objc_getAssociatedObject(self, @selector(stateHookInstalled)) boolValue];
}

- (void)setStateHookInstalled:(BOOL)installed {
    objc_setAssociatedObject(self, @selector(stateHookInstalled), [NSNumber numberWithBool: installed], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)onTitle {
    return objc_getAssociatedObject(self, @selector(onTitle));
}

- (void)setOnTitle:(NSString *)title {
    objc_setAssociatedObject(self, @selector(onTitle), title, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!self.stateHookInstalled) {
        self.stateHookInstalled = YES;
        [self installStateHook];
    }
}

- (NSString *)offTitle {
    return objc_getAssociatedObject(self, @selector(offTitle));
}

- (void)setOffTitle:(NSString *)offTitle {
    objc_setAssociatedObject(self, @selector(offTitle), offTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!self.stateHookInstalled) {
        self.stateHookInstalled = YES;
        [self installStateHook];
    }
}

- (void) installStateHook {
    // KVO to check state, and re-set title if state is changed

    [self addObserver: self forKeyPath: @"state" options: NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context: NULL];
}

- (void) uninstallStateHook {
    if (self.stateHookInstalled) {
        [self removeObserver: self forKeyPath: @"state"];
    }
}

- (void) dealloc {
    [self uninstallStateHook];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString: @"state"]) {
        switch (self.state) {
        case NSOnState:
            self.title = self.onTitle;
            break;  
        case NSOffState:
            self.title = self.offTitle;
            break;
        default:
            break;
        }
    }
}


@end
