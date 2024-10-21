#import <UIKit/UIKit.h>
#import "../Wallpaper/Wallpaper.h"

NS_ASSUME_NONNULL_BEGIN

@interface HUDRootViewController: UIViewController

@property (nonatomic, strong) Wallpaper *wallpaper;
@property (nonatomic, strong) NSTimer *wallpaperTimer;
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) double interval;

@end

NS_ASSUME_NONNULL_END
