//
//  IDVersionChecker.m
//  IRKitDock
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IDAppDelegate.h"
#import "IDMenuletView.h"
#import "IDMenuletController.h"
#import "IDVersionChecker.h"

@interface IDAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) IDMenuletView *menuletView;
@property (nonatomic, strong) IDVersionChecker *versionChecker;

@end

@implementation IDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];
    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength:thickness];

    self.menuletView = [[IDMenuletView alloc] initWithFrame:(NSRect){.size={thickness, thickness}}];
    self.menuletView.controller = [[IDMenuletController alloc] init];

    [self.item setView:self.menuletView];
    [self.item setHighlightMode:NO];

    self.versionChecker = [[IDVersionChecker alloc] init];
    self.versionChecker.delegate = self;

    // check every 24 hours
    [self.versionChecker checkWithInterval:24. * 60. * 60.];
}

#pragma mark - IDVersionCheckerDelegate

- (void) checker: (IDVersionChecker*) checker didDownloadNewFirmware: (NSData*) data {
    LOG( @"checker: %@", checker );
}

@end
