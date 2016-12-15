//
//  AliPushManager.h
//  ReactNativeAliyunOneSdk
//
//  Created by 王舵 on 2016/12/14.
//  Copyright © 2016年 王舵. All rights reserved.
//

#import "RCTEventEmitter.h"

@interface AliPushManager : RCTEventEmitter

+ (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
+ (void)didReceiveRemoteNotification:(NSDictionary *)notification;
+ (void)didReceiveLocalNotification:(UILocalNotification *)notification;
//+ (void)didRegisterForAliDevice:(NSString *)deviceId;
@property NSString* deviceId;
@end
