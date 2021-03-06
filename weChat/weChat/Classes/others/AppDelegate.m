//
//  AppDelegate.m
//  weChat
//
//  Created by XSUNT45 on 17/3/7.
//  Copyright © 2017年 XSUNT45. All rights reserved.
//

#import "AppDelegate.h"
@import CocoaLumberjack;
#import "WCNavController.h"



@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // 沙盒的路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSLog(@"%@",path);
    
//    setenv("XcodeColors", "YES", 0);//XcodeColors插件输出颜色不变
    static const int ddLogLevel = DDLogLevelVerbose;//定义日志级别
    
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];// 启用颜色区分
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];
    
    DDLogVerbose(@"Verbose");    // gray
    DDLogDebug(@"Debug");        // green
    DDLogInfo(@"Info");          // pink
    DDLogWarn(@"Warn");          // orange
    DDLogError(@"Error");        // red
    
    //设置导航栏样式
    [WCNavController setupNavTheme];
    
    // 从沙里加载用户的数据到单例
    [[WCUserInfo sharedWCUserInfo] loadUserInfoFromSanbox];
    
    
    // 判断用户的登录状态，YES 直接来到主界面
    if([WCUserInfo sharedWCUserInfo].loginStatus){
        UIStoryboard *storayobard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.window.rootViewController = storayobard.instantiateInitialViewController;
        
        // 自动登录服务
        [[WCXMPPTool sharedWCXMPPTool] xmppUserLogin:[WCUserInfo sharedWCUserInfo].user completion:nil];
    }
    
    //注册本地通知
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [application registerUserNotificationSettings:settings];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
