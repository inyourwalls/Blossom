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
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(screenBrightnessDidChange:)
            name:UIScreenBrightnessDidChangeNotification
            object:nil];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(deviceOrientationDidChange:)
            name:UIDeviceOrientationDidChangeNotification
            object:nil];
    }
#endif
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    
    NSString* contentsFilePath = [GetStandardUserDefaults() stringForKey:@"LatestWallpaperContentsFilePath"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:contentsFilePath]) {
        NSError *error = nil;
        NSString *fileContents = [NSString stringWithContentsOfFile:contentsFilePath
                                    encoding:NSUTF8StringEncoding
                                    error:&error];
            
        if (error) {
            NSLog(@"Failed to read file: %@", error.localizedDescription);
            return;
        }
        
        if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
            NSLog(@"Device is in Portrait orientation.");
            
            NSString *modifiedContents = [fileContents stringByReplacingOccurrencesOfString:@"landscape-layer_background.HEIC"
                                            withString:@"portrait-layer_background.HEIC"];
                    
            [modifiedContents writeToFile:contentsFilePath
                              atomically:YES
                              encoding:NSUTF8StringEncoding
                              error:&error];
        } else if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
            NSLog(@"Device is in Landscape orientation.");
            
            NSString *modifiedContents = [fileContents stringByReplacingOccurrencesOfString:@"portrait-layer_background.HEIC"
                                            withString:@"landscape-layer_background.HEIC"];
                    
            [modifiedContents writeToFile:contentsFilePath
                              atomically:YES
                              encoding:NSUTF8StringEncoding
                              error:&error];
        } else {
            NSLog(@"Device orientation is unknown or flat.");
        }
    } else {
        NSLog(@"Failed to find Contents.json file. Was wallpaper deleted?");
    }
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
