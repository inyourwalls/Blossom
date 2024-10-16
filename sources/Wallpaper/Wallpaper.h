#import <Foundation/Foundation.h>

@interface Wallpaper: NSObject
- (void) enumerateProcessesUsingBlock:(void (^)(pid_t pid, NSString *executablePath, BOOL *stop))enumerator;
- (void) killall: (NSString*) processName withSoftly: (BOOL) softly;
- (void) restartPoster;
@end
