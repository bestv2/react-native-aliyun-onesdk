package aliyun.wind.onesdk.push;

/**
 * Created by wangduo on 2016/12/13.
 */

//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.alibaba.fastjson.JSON;
import com.alibaba.sdk.android.push.AgooMessageReceiver;
import com.alibaba.sdk.android.push.CloudPushService;
import com.alibaba.sdk.android.push.MessageReceiver;
import com.alibaba.sdk.android.push.noonesdk.PushServiceFactory;
import com.alibaba.sdk.android.push.notification.CPushMessage;
import com.facebook.react.ReactApplication;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class AliPushReceiver extends AgooMessageReceiver {

    // 消息接收部分的LOG_TAG
    public static final String REC_TAG = "AliPushReceiver";
    final static String NOTIFICATION_ID = "notificationId";

    public void onHandleCall(Context context, Intent intent) {
        int id = intent.getIntExtra(NOTIFICATION_ID, 0);
        long currentTime = System.currentTimeMillis();
        Log.i("ReactSystemNotification", "NotificationPublisher: Prepare To Publish: " + id + ", Now Time: " + currentTime);
        Bundle bundle = intent.getExtras();
        String msgBody = bundle.getString("body");
        Map mapData = (Map) JSON.parse(msgBody);
        Log.i("REC_TAG", "type:" + mapData.get("type"));
        int type;
        try {
            type = (int)mapData.get("type");
            if(type == 1){
                new AliPushHelper((Application) context.getApplicationContext()).sendToNotificationCentre(bundle);
            }else if(type == 2){
                receiveMessage((Application) context.getApplicationContext(), (String) mapData.get("title"), (String) mapData.get("summary"));

            }else {
                Log.i(REC_TAG, "Wrong message Type「" + type + "」 Define!");

            }
        } catch (Throwable e) {
            Log.e("Wrong message Type", e.getMessage());
//            e.printStackTrace();
            return;
        }
    }

    public void receiveMessage(Application context, String title, String content) {
        ReactContext mReactContext = ((ReactApplication) context).getReactNativeHost().getReactInstanceManager().getCurrentReactContext();
        WritableMap params = Arguments.createMap();
        params.putString("title", title);
        params.putString("content", content);
        if (mReactContext.hasActiveCatalystInstance()) {
            mReactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit("aliMessageReceived", params);
        }
    }


//    @Override
//    protected void onNotificationReceivedInApp(Context context, String title, String summary, Map<String, String> extraMap, int openType, String openActivity, String openUrl) {
//        Log.i(REC_TAG,"onNotificationReceivedInApp ： " + " : " + title + " : " + summary + "  " + extraMap + " : " + openType + " : " + openActivity + " : " + openUrl);
//    }


    /**
     * 从通知栏打开通知的扩展处理
     *
     * @param context
     * @param title
     * @param summary
     * @param extraMap
     */
    @Override
    public void onNotificationOpened(Context context, String title, String summary, String extraMap) {
        CloudPushService cloudPushService = PushServiceFactory.getCloudPushService();
//        cloudPushService.setNotificationSoundFilePath();
        Log.i(REC_TAG, "onNotificationOpened ： " + " : " + title + " : " + summary + " : " + extraMap);
        ReactContext mReactContext = ((ReactApplication) context).getReactNativeHost().getReactInstanceManager().getCurrentReactContext();
        WritableMap params = Arguments.createMap();
        params.putString("title", title);
        params.putString("content", summary);
        if (mReactContext.hasActiveCatalystInstance()) {
            mReactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit("onNotificationOpened", params);
        }
    }


    @Override
    public void onNotificationRemoved(Context context, String messageId) {
        Log.i(REC_TAG, "onNotificationRemoved ： " + messageId);
        ReactContext mReactContext = ((ReactApplication) context).getReactNativeHost().getReactInstanceManager().getCurrentReactContext();
        WritableMap params = Arguments.createMap();
        if (mReactContext.hasActiveCatalystInstance()) {
            mReactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit("onNotificationRemoved", params);
        }
    }

    @Override
    protected void onNotificationClickedWithNoAction(Context context, String s, String s1, String s2) {

    }


//    @Override
//    protected void onNotificationClickedWithNoAction(Context context, String title, String summary, String extraMap) {
//        Log.i(REC_TAG,"onNotificationClickedWithNoAction ： " + " : " + title + " : " + summary + " : " + extraMap);
//    }
}
