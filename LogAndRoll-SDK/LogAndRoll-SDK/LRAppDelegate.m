//
//  LRAppDelegate.m
//  LogAndRoll-SDK
//
//  Created by Peter Willemsen on 27-10-13.
//  Copyright (c) 2013 CodeBuffet. All rights reserved.
//

#import "LRAppDelegate.h"
#import "LRMain.h"

@implementation LRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [LRMain launchWithApplicationName:@"test" andAPIKey:@"GGyFeOJEeTjEuyajwR1y3rP3y9tEX7kEJK5QEb7IGnO"];
    
    LogNRoll(@"Current User", @"peterwilli");
    
    [self performSelector:@selector(lol1) withObject:nil afterDelay:5];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) lol1
{
    LogNRoll(@"Web Request", @"POSTING to http://api.myapp.com/logout");
    [self performSelector:@selector(lol2) withObject:nil afterDelay:5];
}

- (void) lol2
{
    LogNRoll(@"Web Request", @"POSTING to http://api.myapp.com/login");
    LogNRoll(@"Current User", @"kuroiroy");
    [self performSelector:@selector(lol3) withObject:nil afterDelay:12];
}

- (void) lol3
{
    LogNRoll(@"Web Request", @"POSTING to http://api.myapp.com/new_post");
    [self performSelector:@selector(lol4) withObject:nil afterDelay:1];
}

- (void) lol4
{
    LogNRoll(@"Web Error", @"Error: cannot find picture data");
    NSLog(@"Done");
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
