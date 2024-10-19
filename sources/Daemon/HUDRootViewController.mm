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
        if ([app.applicationIdentifier isEqualToString:@"ch.xxtou.hudapp"])
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

#if !TARGET_IPHONE_SIMULATOR
static void SpringBoardLockStatusChanged
(CFNotificationCenterRef center,
 void *observer,
 CFStringRef name,
 const void *object,
 CFDictionaryRef userInfo)
{
    NSString *lockState = (__bridge NSString *)name;
    if ([lockState isEqualToString:@NOTIFY_UI_LOCKSTATE])
    {
        mach_port_t sbsPort = SBSSpringBoardServerPort();
        
        if (sbsPort == MACH_PORT_NULL)
            return;
        
        BOOL isLocked;
        BOOL isPasscodeSet;
        SBGetScreenLockStatus(sbsPort, &isLocked, &isPasscodeSet);

        if (!isLocked)
        {
//            [rootViewController.view setHidden:NO];
        }
        else
        {
//            [rootViewController.view setHidden:YES];
        }
    }
}
#endif

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

    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        LaunchServicesApplicationStateChanged,
        CFSTR(NOTIFY_LS_APP_CHANGED),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
    
    CFNotificationCenterAddObserver(
        darwinCenter,
        (__bridge const void *)self,
        SpringBoardLockStatusChanged,
        CFSTR(NOTIFY_UI_LOCKSTATE),
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
#endif
}

- (BOOL)usesCustomFontSize { return NO; }
- (CGFloat)realCustomFontSize { return 0; }
- (BOOL)usesCustomOffset { return NO; }
- (CGFloat)realCustomOffsetX { return 0; }
- (CGFloat)realCustomOffsetY { return 0; }

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self registerNotifications];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Wallpaper *wallpaper = [[Wallpaper alloc] init];
    
    [wallpaper restartPoster];
    
    double interval = 5.3;

    [NSTimer scheduledTimerWithTimeInterval:interval repeats: true block: ^(NSTimer * _Nonnull timer) {
        [wallpaper restartPoster];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    notify_post(NOTIFY_LAUNCHED_HUD);
}


@end
