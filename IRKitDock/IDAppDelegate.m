#import "IDAppDelegate.h"
#import "IDMenuletView.h"
#import "IDMenuletController.h"

@interface IDAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) IDMenuletView *menuletView;

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
}

@end
