//
//  CEAppDelegate.m
//  LinkedInAPI
//
//  Created by Chris Eidhof on 6/27/12.
//  Copyright (c) 2012 Chris Eidhof. All rights reserved.
//

#import "CEAppDelegate.h"
#import "LinkedInAPI.h"

@interface CEAppDelegate () {
    LinkedInAPI* api;
}

@end

@implementation CEAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.window.bounds];
    [self.window addSubview:webView];
    NSString* apikey = YOUR_API_KEY;
    NSString* secretkey = YOUR_API_SECRET;   
    NSString* token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
    NSString* secret = [[NSUserDefaults standardUserDefaults] objectForKey:@"secret"];

    api = [[LinkedInAPI alloc] initWithConsumerKey:apikey secret:secretkey];
    if(token && secret) {
        [api setToken:token andSecret:secret];
        [self userLoggedInWithToken:token secret:secret];
    } else {
        webView.delegate = api;
        [api startAuthentication:^(NSURL *url) {
            NSLog(@"url class: %@", [url class]);
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            [webView loadRequest:request];
        }];
    }
    
    api.delegate = self;
    
    return YES;
}

- (void)userLoggedInWithToken:(NSString*)token secret:(NSString*)secret {
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"token"];
    [[NSUserDefaults standardUserDefaults] setObject:secret forKey:@"secret"];
    NSLog(@"user logged in");
    NSString* messageBody = [NSString stringWithFormat:@"message: %@", [NSDate date]];
    [api sendMessageWithBody:messageBody title:@"msg title" recipient:@"/people/~" success:^{
        NSLog(@"message sent!");
    } failureHandler:^(NSError *error) {
        NSLog(@"message error: %@", error);
    }];
//    [api getConnections:^(id result) {
//        NSArray* connections = result;
//        NSLog(@"connections: %d, last item: %@", [connections count], [connections lastObject]);
//    } failureHandler:^(NSError *error) {
//        NSLog(@"connections error: %@", error);
//    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
