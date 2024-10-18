#import "Wallpaper.h"
#import <spawn.h>
#import <sys/sysctl.h>

@implementation LiveWallpaper
@end

@implementation Wallpaper

- (void)deleteSnapshots: (NSString*) wallpaperRootPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:wallpaperRootPath error:&error];
    
    if (error) NSLog(@"Error reading directory: %@", error);
    
    for (NSString *item in contents) {
        NSString *fullPath = [wallpaperRootPath stringByAppendingPathComponent:item];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && !isDirectory) {
            if ([item localizedCaseInsensitiveContainsString:@"Snapshot"]) {
                [fileManager removeItemAtPath:fullPath error:nil];
            }
        }
    }
}

- (NSMutableArray *)getDirectories:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:&error];
    
    if (error) {
        NSLog(@"Error reading directory: %@", error);
        return nil;
    }
    
    NSMutableArray *folders = [NSMutableArray array];
    for (NSString *item in contents) {
        NSString *fullPath = [path stringByAppendingPathComponent:item];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory] && isDirectory) {
            [folders addObject:item];
        }
    }
    
    return folders;
}

-(NSString*)getPosterBoardRoot {
    PrivateApi_LSApplicationWorkspace* _workspace = [NSClassFromString(@"LSApplicationWorkspace") new];
    NSArray* allInstalledApplications = [_workspace allInstalledApplications];
    
    for(id proxy in allInstalledApplications) {
        PrivateApi_LSApplicationProxy* _applicationProxy = (PrivateApi_LSApplicationProxy*)proxy;
        
        if([_applicationProxy.bundleIdentifier isEqualToString:@"com.apple.PosterBoard"]) {
            NSString* dataStore = [NSString stringWithFormat:@"%@/Library/Application Support/PRBPosterExtensionDataStore", _applicationProxy.containerURL.path];
            
            dataStore = [dataStore stringByReplacingOccurrencesOfString:@"/private" withString:@""];
            
            NSMutableArray* dirs = [self getDirectories:dataStore];
            
            NSString* path = [NSString stringWithFormat:@"%@/%@/Extensions/com.apple.PhotosUIPrivate.PhotosPosterProvider/configurations", dataStore, dirs[0]];
            
            return path;
        }
    }
    
    return nil;
}

- (NSArray<LiveWallpaper *> *)getLiveWallpapers {
    NSMutableArray<LiveWallpaper *> *liveWallpapers = [NSMutableArray array];
    NSString* root = [self getPosterBoardRoot];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for(NSString* configurationPath in [self getDirectories:root]) {
        NSString* versions = [NSString stringWithFormat:@"%@/%@/versions", root, configurationPath];
        NSString* version = [self getDirectories:versions][0];
        
        NSString* contents = [NSString stringWithFormat:@"%@/%@/contents",versions,version];
        NSString* contentDirectory = [self getDirectories:contents][0];
        
        NSString* wallpaperDirectory = [NSString stringWithFormat:@"%@/%@/output.layerStack", contents, contentDirectory];
        
        NSString* liveWallpaperPath = [NSString stringWithFormat:@"%@/portrait-layer_settling-video.MOV", wallpaperDirectory];
        
        if([fileManager fileExistsAtPath:liveWallpaperPath]) {
            LiveWallpaper* wallpaper = [[LiveWallpaper alloc] init];
            
            wallpaper.wallpaperRootDirectory = [NSString stringWithFormat:@"%@/%@", contents, contentDirectory];
            wallpaper.path = liveWallpaperPath;
            wallpaper.stillImagePath = [NSString stringWithFormat:@"%@/portrait-layer_background.HEIC", wallpaperDirectory];
            wallpaper.contentsPath = [NSString stringWithFormat:@"%@/Contents.json", wallpaperDirectory];
            wallpaper.wallpaperVersionDirectory = [NSString stringWithFormat:@"%@/%@", versions, version];
            
            [liveWallpapers addObject:wallpaper];
        }
    }
    
    return [liveWallpapers copy];
}

- (void)enumerateProcessesUsingBlock:(void (^)(pid_t, NSString *, BOOL *))enumerator {
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    int count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        @autoreleasepool {
            pid_t pid = info[i].kp_proc.p_pid;
            if (pid == 0) {
                continue;
            }
            size_t size = maxArgumentSize;
            char* buffer = (char *)malloc(length);
            if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
                NSString* executablePath = [NSString stringWithCString:(buffer+sizeof(int)) encoding:NSUTF8StringEncoding];
                
                BOOL stop = NO;
                enumerator(pid, executablePath, &stop);
                if(stop)
                {
                    free(buffer);
                    break;
                }
            }
            free(buffer);
        }
    }
    free(info);
}

- (void)killall:(NSString *)processName withSoftly:(BOOL)softly {
    [self enumerateProcessesUsingBlock:(^(pid_t pid, NSString* executablePath, BOOL* stop) {
        if([executablePath.lastPathComponent isEqualToString:processName]) {
            if(softly) kill(pid, SIGTERM);
            else kill(pid, SIGKILL);
        }
    })];
}

- (void)restartPoster {
    [self killall:@"PhotosPosterProvider" withSoftly:TRUE];
}

- (void)respring {
    [self killall:@"SpringBoard" withSoftly:TRUE];
}

@end
