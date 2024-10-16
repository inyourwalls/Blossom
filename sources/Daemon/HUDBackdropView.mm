#import "HUDBackdropView.h"

@implementation HUDBackdropView

+ (Class)layerClass {
    return [NSClassFromString(@"CABackdropLayer") class];
}

@end
