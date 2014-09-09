
#import "VGAppDelegate.h"
#import "Vangogh.h"
#import "VGDemoViewController.h"


@implementation VGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    VGDemoViewController *demo = [VGDemoViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:demo];

    self.window = [[VGWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end


int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(VGAppDelegate.class));
    }
}
