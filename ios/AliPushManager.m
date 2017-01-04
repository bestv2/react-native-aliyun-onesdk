//
//  AliPushManager.m
//  ReactNativeAliyunOneSdk
//
//  Created by 王舵 on 2016/12/14.
//  Copyright © 2016年 王舵. All rights reserved.
//

#import "AliPushManager.h"



#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import <CloudPushSDK/CloudPushSDK.h>
#import <CloudPushSDK/CCPSysMessage.h>
//#import <UserNotifications/UserNotifications.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0

#define UIUserNotificationTypeAlert UIRemoteNotificationTypeAlert
#define UIUserNotificationTypeBadge UIRemoteNotificationTypeBadge
#define UIUserNotificationTypeSound UIRemoteNotificationTypeSound
#define UIUserNotificationTypeNone  UIRemoteNotificationTypeNone
#define UIUserNotificationType      UIRemoteNotificationType

#endif
NSString *const RemoteNotificationsRegistered = @"RemoteNotificationsRegistered";

NSString *const RegisterUserNotificationSettings = @"RegisterUserNotificationSettings";

NSString *const LocalNotificationReceived = @"LocalNotificationReceived";
NSString *const RemoteNotificationReceived = @"RemoteNotificationReceived";


NSString *const AliErrorUnableToRequestPermissions = @"E_UNABLE_TO_REQUEST_PERMISSIONS";

@implementation RCTConvert (UILocalNotification)

+ (UILocalNotification *)UILocalNotification:(id)json
{
	NSDictionary<NSString *, id> *details = [self NSDictionary:json];
	UILocalNotification *notification = [UILocalNotification new];
	notification.fireDate = [RCTConvert NSDate:details[@"fireDate"]] ?: [NSDate date];
	notification.alertBody = [RCTConvert NSString:details[@"alertBody"]];
	notification.alertAction = [RCTConvert NSString:details[@"alertAction"]];
	notification.soundName = [RCTConvert NSString:details[@"soundName"]] ?: UILocalNotificationDefaultSoundName;
	notification.userInfo = [RCTConvert NSDictionary:details[@"userInfo"]];
	notification.category = [RCTConvert NSString:details[@"category"]];
	if (details[@"applicationIconBadgeNumber"]) {
		notification.applicationIconBadgeNumber = [RCTConvert NSInteger:details[@"applicationIconBadgeNumber"]];
	}
	return notification;
}

@end

@implementation AliPushManager
{
	RCTPromiseResolveBlock _requestPermissionsResolveBlock;
	RCTPromiseRejectBlock _requestPermissionsRejectBlock;
}

static NSDictionary *RCTFormatLocalNotification(UILocalNotification *notification)
{
	NSMutableDictionary *formattedLocalNotification = [NSMutableDictionary dictionary];
	if (notification.fireDate) {
		NSDateFormatter *formatter = [NSDateFormatter new];
		[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
		NSString *fireDateString = [formatter stringFromDate:notification.fireDate];
		formattedLocalNotification[@"fireDate"] = fireDateString;
	}
	formattedLocalNotification[@"alertAction"] = RCTNullIfNil(notification.alertAction);
	formattedLocalNotification[@"alertBody"] = RCTNullIfNil(notification.alertBody);
	formattedLocalNotification[@"applicationIconBadgeNumber"] = @(notification.applicationIconBadgeNumber);
	formattedLocalNotification[@"category"] = RCTNullIfNil(notification.category);
	formattedLocalNotification[@"soundName"] = RCTNullIfNil(notification.soundName);
	formattedLocalNotification[@"userInfo"] = RCTNullIfNil(RCTJSONClean(notification.userInfo));
	return formattedLocalNotification;
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
	return dispatch_get_main_queue();
}

- (void)startObserving
{

	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(handleLocalNotificationReceived:)
																							 name:LocalNotificationReceived
																						 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(handleRemoteNotificationReceived:)
																							 name:RemoteNotificationReceived
																						 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(handleRemoteNotificationsRegistered:)
																							 name:RemoteNotificationsRegistered
																						 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(handleRegisterUserNotificationSettings:)
																							 name:RegisterUserNotificationSettings
																						 object:nil];
	[self registerMessageReceive];
}
#pragma mark Receive Message
/**
 *    注册推送消息到来监听
 */
- (void)registerMessageReceive {
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(onMessageReceived:)
																							 name:@"CCPDidReceiveMessageNotification"
																						 object:nil];
}
- (void)stopObserving
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents
{
	return @[		 @"localNotificationReceived",
					 @"remoteNotificationReceived",
					 @"remoteNotificationsRegistered",
					 @"aliMessageReceived",
					 @"registerUserNotificationSettings"];
}

// TODO: Once all JS call sites for popInitialNotification have
// been removed we can get rid of this
- (NSDictionary<NSString *, id> *)constantsToExport
{
	return @{};

}

+ (void)didRegisterUserNotificationSettings:(__unused UIUserNotificationSettings *)notificationSettings
{
	if ([UIApplication instancesRespondToSelector:@selector(registerForRemoteNotifications)]) {
		[[UIApplication sharedApplication] registerForRemoteNotifications];
		[[NSNotificationCenter defaultCenter] postNotificationName:RegisterUserNotificationSettings
																												object:self
																											userInfo:@{@"notificationSettings": notificationSettings}];
	}
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{

	[CloudPushSDK registerDevice:deviceToken withCallback:^(CloudPushCallbackResult *res) {
		if (res.success) {
			NSLog(@"Register deviceToken success.");
		} else {
			NSLog(@"Register deviceToken failed, error: %@", res.error);
		}
	}];
	NSMutableString *hexString = [NSMutableString string];
	NSUInteger deviceTokenLength = deviceToken.length;
	const unsigned char *bytes = deviceToken.bytes;
	for (NSUInteger i = 0; i < deviceTokenLength; i++) {
		[hexString appendFormat:@"%02x", bytes[i]];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:RemoteNotificationsRegistered
																											object:self
																										userInfo:@{@"deviceToken" : [hexString copy]}];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)notification
{
	[CloudPushSDK handleReceiveRemoteNotification:notification];
	[[NSNotificationCenter defaultCenter] postNotificationName:RemoteNotificationReceived
																											object:self
																										userInfo:notification];

}

+ (void)didReceiveLocalNotification:(UILocalNotification *)notification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LocalNotificationReceived
																											object:self
																										userInfo:RCTFormatLocalNotification(notification)];
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification
{
	[self sendEventWithName:@"localNotificationReceived" body:notification.userInfo];
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification
{
	[self sendEventWithName:@"remoteNotificationReceived" body:notification.userInfo];
}

- (void)handleRemoteNotificationsRegistered:(NSNotification *)notification
{
	[self sendEventWithName:@"remoteNotificationsRegistered" body:notification.userInfo];
}
/**
 *    处理到来推送消息
 *
 *    @param     notification
 */
- (void)onMessageReceived:(NSNotification *)notification {
	CCPSysMessage *message = [notification object];
	NSString *title = [[NSString alloc] initWithData:message.title encoding:NSUTF8StringEncoding];
	NSString *body = [[NSString alloc] initWithData:message.body encoding:NSUTF8StringEncoding];
	[self sendEventWithName:@"aliMessageReceived" body: @{@"title":title,@"content":body}];
}
- (void)handleRegisterUserNotificationSettings:(NSNotification *)notification
{
	
	UIUserNotificationSettings *notificationSettings = notification.userInfo[@"notificationSettings"];
	NSDictionary *notificationTypes = @{
																			@"alert": @((notificationSettings.types & UIUserNotificationTypeAlert) > 0),
																			@"sound": @((notificationSettings.types & UIUserNotificationTypeSound) > 0),
																			@"badge": @((notificationSettings.types & UIUserNotificationTypeBadge) > 0),
																			};
	[self sendEventWithName:@"registerUserNotificationSettings" body:notificationTypes];
}

/**
 * Update the application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(setApplicationIconBadgeNumber:(NSInteger)number)
{
	RCTSharedApplication().applicationIconBadgeNumber = number;
}

/**
 * Get the current application icon badge number on the home screen
 */
RCT_EXPORT_METHOD(getApplicationIconBadgeNumber:(RCTResponseSenderBlock)callback)
{
	callback(@[@(RCTSharedApplication().applicationIconBadgeNumber)]);
}

RCT_EXPORT_METHOD(requestPermissions:(NSDictionary *)permissions
									resolver:(RCTPromiseResolveBlock)resolve
									rejecter:(RCTPromiseRejectBlock)reject)
{
	if (RCTRunningInAppExtension()) {
		reject(AliErrorUnableToRequestPermissions, nil, RCTErrorWithMessage(@"Requesting push notifications is currently unavailable in an app extension"));
		return;
	}
	
	if (_requestPermissionsResolveBlock != nil) {
		RCTLogError(@"Cannot call requestPermissions twice before the first has returned.");
		return;
	}
	
	_requestPermissionsResolveBlock = resolve;
	_requestPermissionsRejectBlock = reject;
	
	UIUserNotificationType types = UIUserNotificationTypeNone;
	if (permissions) {
		if ([RCTConvert BOOL:permissions[@"alert"]]) {
			types |= UIUserNotificationTypeAlert;
		}
		if ([RCTConvert BOOL:permissions[@"badge"]]) {
			types |= UIUserNotificationTypeBadge;
		}
		if ([RCTConvert BOOL:permissions[@"sound"]]) {
			types |= UIUserNotificationTypeSound;
		}
	} else {
		types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
	}
	
	UIApplication *app = RCTSharedApplication();

//	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
//		[[UIApplication sharedApplication] registerForRemoteNotifications];
// 		[UNUserNotificationCenter currentNotificationCenter].delegate = [[UIApplication sharedApplication] delegate];
//	}else
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
		// iOS 8 Notifications
		[app registerUserNotificationSettings:
		 [UIUserNotificationSettings settingsForTypes:
			(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
																			 categories:nil]];
		[app registerForRemoteNotifications];
		
		
	}
	else {
		// iOS < 8 Notifications
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		 (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
	}
	if([CloudPushSDK getDeviceId] != nil){
		_requestPermissionsResolveBlock([CloudPushSDK getDeviceId]);
		_requestPermissionsResolveBlock = nil;
		_requestPermissionsRejectBlock = nil;
	}else {
		// SDK初始化
		NSString *appKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"com.alibaba.app.appkey"];
		NSString *appSecret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"com.alibaba.app.appsecret"];
//		NSLog(@"appKey:%@,appSecret:%@",appKey,appSecret);
		[CloudPushSDK asyncInit:appKey appSecret:appSecret callback:^(CloudPushCallbackResult *res) {
		if (res.success) {
			_requestPermissionsResolveBlock(self.deviceId);
		} else {
			_requestPermissionsRejectBlock(@"0",@"初始化失败",@"");
		}
		_requestPermissionsResolveBlock = nil;
		_requestPermissionsRejectBlock = nil;
	}];
	}
	

}
RCT_EXPORT_METHOD(bindAccount:(NSString *)account resolver:(RCTPromiseResolveBlock)resolve
									rejecter:(RCTPromiseRejectBlock)reject)
{
	[CloudPushSDK bindAccount:account withCallback:^(CloudPushCallbackResult *res) {
				NSLog(@"bind res:%d.", res.success);
				resolve(@"1");
	
	}];
}
RCT_EXPORT_METHOD(unbindAccount: (RCTPromiseResolveBlock)resolve
									rejecter:(RCTPromiseRejectBlock)reject)
{
	[CloudPushSDK unbindAccount:^(CloudPushCallbackResult *res) {
				resolve(@"1");

	}];
}

RCT_EXPORT_METHOD(abandonPermissions)
{
	[RCTSharedApplication() unregisterForRemoteNotifications];
}

RCT_EXPORT_METHOD(checkPermissions:(RCTResponseSenderBlock)callback)
{
	if (RCTRunningInAppExtension()) {
		callback(@[@{@"alert": @NO, @"badge": @NO, @"sound": @NO}]);
		return;
	}
	
	NSUInteger types = 0;
	if ([UIApplication instancesRespondToSelector:@selector(currentUserNotificationSettings)]) {
		types = [RCTSharedApplication() currentUserNotificationSettings].types;
	} else {
		
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
		
		types = [RCTSharedApplication() enabledRemoteNotificationTypes];
		
#endif
		
	}
	
	callback(@[@{
							 @"alert": @((types & UIUserNotificationTypeAlert) > 0),
							 @"badge": @((types & UIUserNotificationTypeBadge) > 0),
							 @"sound": @((types & UIUserNotificationTypeSound) > 0),
							 }]);
}

RCT_EXPORT_METHOD(presentLocalNotification:(UILocalNotification *)notification)
{
	[RCTSharedApplication() presentLocalNotificationNow:notification];
}

RCT_EXPORT_METHOD(scheduleLocalNotification:(UILocalNotification *)notification)
{
	[RCTSharedApplication() scheduleLocalNotification:notification];
}

RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
	[RCTSharedApplication() cancelAllLocalNotifications];
}

RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary<NSString *, id> *)userInfo)
{
	for (UILocalNotification *notification in [UIApplication sharedApplication].scheduledLocalNotifications) {
		__block BOOL matchesAll = YES;
		NSDictionary<NSString *, id> *notificationInfo = notification.userInfo;
		// Note: we do this with a loop instead of just `isEqualToDictionary:`
		// because we only require that all specified userInfo values match the
		// notificationInfo values - notificationInfo may contain additional values
		// which we don't care about.
		[userInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
			if (![notificationInfo[key] isEqual:obj]) {
				matchesAll = NO;
				*stop = YES;
			}
		}];
		if (matchesAll) {
			[[UIApplication sharedApplication] cancelLocalNotification:notification];
		}
	}
}

RCT_EXPORT_METHOD(getInitialNotification:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject)
{
  NSMutableDictionary<NSString *, id> *initialNotification =
    [self.bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] mutableCopy];

  UILocalNotification *initialLocalNotification =
    self.bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];

  if (initialNotification) {
    initialNotification[@"remote"] = @YES;
    resolve(initialNotification);
  } else if (initialLocalNotification) {
    resolve(RCTFormatLocalNotification(initialLocalNotification));
  } else {
    resolve((id)kCFNull);
  }
}

RCT_EXPORT_METHOD(getInitialNotification2: (RCTResponseSenderBlock )callback)
{
	NSDictionary<NSString *, id> *initialNotification =
	self.bridge.launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
	
	UILocalNotification *initialLocalNotification =
	self.bridge.launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
	
	if (initialNotification) {
		callback(@[initialNotification]);
	} else if (initialLocalNotification) {
			callback(@[initialLocalNotification]);

	} else {
			callback(@[@"0"]);
	}
}
RCT_EXPORT_METHOD(getScheduledLocalNotifications:(RCTResponseSenderBlock)callback)
{
	NSArray<UILocalNotification *> *scheduledLocalNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
	NSMutableArray<NSDictionary *> *formattedScheduledLocalNotifications = [NSMutableArray new];
	for (UILocalNotification *notification in scheduledLocalNotifications) {
		[formattedScheduledLocalNotifications addObject:RCTFormatLocalNotification(notification)];
	}
	callback(@[formattedScheduledLocalNotifications]);
}

@end
