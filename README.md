# react-native-aliyun-onesdk

#install
npm install react-native-aliyun-onesdk --save

#usage
react-native link react-native-aliyun-onesdk
#configuration :
ios: https://help.aliyun.com/document_detail/30072.html  
android: https://help.aliyun.com/document_detail/30064.html

##ios
mkdir yourProject/ios/OneSDK
put the aliyun frameworks to the dir  
add com.alibaba.app.appkey/com.alibaba.app.appsecret to your info.plist
Appdelegate.m
```objective-c
	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
	  ...
	  [self initCloudPush];
	  ...
	}
	- (void)initCloudPush {
	// SDK初始化
	NSString *appKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"com.alibaba.app.appkey"];
	NSString *appSecret = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"com.alibaba.app.appsecret"];
	[CloudPushSDK asyncInit:appKey appSecret:appSecret callback:^(CloudPushCallbackResult *res) {
		if (res.success) {
		} else {

		}
	}];
	}
	
	#pragma mark Notification Open
	/*
	 *  App处于启动状态时，通知打开回调
	 */
	- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
		NSLog(@"Receive one notification.");
		// 取得APNS通知内容
		NSDictionary *aps = [userInfo valueForKey:@"aps"];
		// 内容
		NSString *content = [aps valueForKey:@"alert"];
		// badge数量
		NSInteger badge = [[aps valueForKey:@"badge"] integerValue]+1;
		// 播放声音
		NSString *sound = [aps valueForKey:@"sound"];
		// 取得Extras字段内容
		NSString *Extras = [userInfo valueForKey:@"Extras"]; //服务端中Extras字段，key是自己定义的
		NSLog(@"content = [%@], badge = [%ld], sound = [%@], Extras = [%@]", content, (long)badge, sound, Extras);
		// iOS badge 清0
		//    application.applicationIconBadgeNumber = badge+1;
		// 通知打开回执上报
		//	 application.applicationIconBadgeNumber = application.applicationIconBadgeNumber+1;
		[AliPushManager didReceiveRemoteNotification:userInfo];
	}
	// Required to register for notifications
	   - (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
	   {
	    [AliPushManager didRegisterUserNotificationSettings:notificationSettings];
	   }
	- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
		NSLog(@"Upload deviceToken to CloudPush server.deviceToken:%@",deviceToken);

		[AliPushManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
	}
```
##android
```java
	@Override
	public void onCreate() {
	  super.onCreate();
	  ...
	  initCloudChannel(this);      
	}
	/**
	     * 初始化云推送通道
	     *
	     * @param applicationContext
	     */
	    private void initCloudChannel(Context applicationContext) {
		PushServiceFactory.init(applicationContext);
		CloudPushService pushService = PushServiceFactory.getCloudPushService();
		pushService.register(applicationContext, new CommonCallback() {
		    @Override
		    public void onSuccess(String response) {
			Log.d(TAG, "init cloudchannel success");
		    }

		    @Override
		    public void onFailed(String errorCode, String errorMessage) {
			Log.d(TAG, "init cloudchannel failed -- errorcode:" + errorCode + " -- errorMessage:" + errorMessage);
		    }
		});
	//注册方法会自动判断是否支持小米系统推送，如不支持会跳过注册。
	//            MiPushRegister.register(applicationContext, "2882303761517489550", "5201748990550");
	//注册方法会自动判断是否支持华为系统推送，如不支持会跳过注册。
	//            HuaWeiRegister.register(applicationContext);
	    }
```
#available
##push 
	remoteNotification
	bindAccount
	unbindAccount
       
