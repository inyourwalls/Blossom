#import <Foundation/Foundation.h>

@interface PrivateApi_LSApplicationWorkspace
- (NSArray*)allInstalledApplications;
@end


@interface PrivateApi_LSApplicationProxy

+ (instancetype)applicationProxyForIdentifier:(NSString*)identifier;
@property (nonatomic, readonly) NSString* localizedShortName;
@property (nonatomic, readonly) NSString* localizedName;
@property (nonatomic, readonly) NSString* bundleIdentifier;
@property (nonatomic, readonly) NSArray* appTags;

@property (nonatomic, readonly) NSString *applicationDSID;
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *applicationType;
@property (nonatomic, readonly) NSNumber *dynamicDiskUsage;
@property (nonatomic, readonly) NSURL *bundleURL;
@property (nonatomic, readonly) NSURL *containerURL;

@property (nonatomic, readonly) NSArray *groupIdentifiers;
@property (nonatomic, readonly) NSNumber *itemID;
@property (nonatomic, readonly) NSString *itemName;
@property (nonatomic, readonly) NSString *minimumSystemVersion;
@property (nonatomic, readonly) NSArray *requiredDeviceCapabilities;
@property (nonatomic, readonly) NSString *roleIdentifier;
@property (nonatomic, readonly) NSString *sdkVersion;
@property (nonatomic, readonly) NSString *shortVersionString;
@property (nonatomic, readonly) NSString *sourceAppIdentifier;
@property (nonatomic, readonly) NSNumber *staticDiskUsage;
@property (nonatomic, readonly) NSString *teamID;
@property (nonatomic, readonly) NSString *vendorName;

@end

@interface LiveWallpaper: NSObject

@property (nonatomic, strong) NSString* wallpaperRootDirectory;
@property (nonatomic, strong) NSString* wallpaperVersionDirectory;
@property (nonatomic, strong) NSString* path;
@property (nonatomic, strong) NSString* stillImagePath;
@property (nonatomic, strong) NSString* contentsPath;

@end


@interface Wallpaper: NSObject
- (void) enumerateProcessesUsingBlock:(void (^)(pid_t pid, NSString *executablePath, BOOL *stop))enumerator;
- (void) killall: (NSString*) processName withSoftly: (BOOL) softly;
- (void) restartPoster;
- (void) restartPosterBoard;
- (void) respring;
- (void) deleteSnapshots: (NSString*) wallpaperRootPath;

- (NSMutableArray*) getDirectories:(NSString*) path;
- (NSString*) getPosterBoardRoot;
- (NSArray<LiveWallpaper *>*) getLiveWallpapers;
@end
