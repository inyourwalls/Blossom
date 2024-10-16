typedef void (^ToggleCallback)(BOOL);

@interface Daemon: NSObject
@property (nonatomic, copy) ToggleCallback callback;

-(void) toggle;
-(BOOL) isEnabled;

-(void) setDelay: (double) delay;
@end
