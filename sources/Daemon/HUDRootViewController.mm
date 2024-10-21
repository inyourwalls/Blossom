#import <notify.h>
#import <objc/runtime.h>
#import <mach/vm_param.h>
#import <Foundation/Foundation.h>

#import "../Wallpaper/Wallpaper.h"
#import "HUDRootViewController.h"

#pragma mark -

#import "UIApplication+Private.h"
#import "LSApplicationProxy.h"
#import "LSApplicationWorkspace.h"
#import "SpringBoardServices.h"

#define NOTIFY_UI_LOCKSTATE    "com.apple.springboard.lockstate"
#define NOTIFY_LS_APP_CHANGED  "com.apple.LaunchServices.ApplicationsChanged"

static void LaunchServicesApplicationStateChanged
(CFNotificationCenterRef center,
 void *observer,
 CFStringRef name,
 const void *object,
 CFDictionaryRef userInfo)
{
    /* Application installed or uninstalled */

    BOOL isAppInstalled = NO;
    
    for (LSApplicationProxy *app in [[objc_getClass("LSApplicationWorkspace") defaultWorkspace] allApplications])
    {
        if ([app.applicationIdentifier isEqualToString:@"com.inyourwalls.blossom"])
        {
            isAppInstalled = YES;
            break;
        }
    }

    if (!isAppInstalled)
    {
        UIApplication *app = [UIApplication sharedApplication];
        [app terminateWithSuccess];
    }
}

#pragma mark - HUDRootViewController

@interface HUDRootViewController (Troll)
@end

@implementation HUDRootViewController {
}

- (void)registerNotifications
{
#if !TARGET_IPHONE_SIMULATOR
    int token;
    notify_register_dispatch(NOTIFY_RELOAD_HUD, &token, dispatch_get_main_queue(), ^(int token) {
        
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(screenBrightnessDidChange:)
        name:UIScreenBrightnessDidChangeNotification
        object:nil];
#endif
}

- (void)screenBrightnessDidChange:(NSNotification *)notification {
    CGFloat brightness = [UIScreen mainScreen].brightness;

    if(brightness < 0.1) {
        if(!self.isPaused) {
            [[self wallpaperTimer] invalidate];
            self.isPaused = YES;
        }
    } else {
        if(self.isPaused) {
            self.wallpaperTimer = [NSTimer scheduledTimerWithTimeInterval:[self interval] repeats:true block:^(NSTimer * _Nonnull timer) {
                [[self wallpaper] restartPoster];
            }];
            self.isPaused = NO;
        }
    }
}

- (BOOL)usesCustomFontSize { return NO; }
- (CGFloat)realCustomFontSize { return 0; }
- (BOOL)usesCustomOffset { return NO; }
- (CGFloat)realCustomOffsetX { return 0; }
- (CGFloat)realCustomOffsetY { return 0; }

- (instancetype)init
{
    self = [super init];
    
    self.wallpaper = [[Wallpaper alloc] init];
    self.interval = 5.3;
    
    if (self) {
        [self registerNotifications];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self wallpaper] restartPoster];

    self.wallpaperTimer = [NSTimer scheduledTimerWithTimeInterval:[self interval] repeats: true block: ^(NSTimer * _Nonnull timer) {
        [[self wallpaper] restartPoster];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    notify_post(NOTIFY_LAUNCHED_HUD);
}


@end
