package aliyun.wind.onesdk.push;

import android.app.Activity;
import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;

import com.alibaba.fastjson.JSONException;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.sdk.android.push.CloudPushService;
import com.alibaba.sdk.android.push.CommonCallback;
import com.alibaba.sdk.android.push.noonesdk.PushServiceFactory;
//import com.alibaba.sdk.android.push.register.HuaWeiRegister;
//import com.alibaba.sdk.android.push.register.MiPushRegister;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import javax.annotation.Nullable;

/**
 * Created by wangduo on 16/3/2.
 */
public class AliPushModule extends ReactContextBaseJavaModule implements ActivityEventListener {
    private ReactContext mReactContext;
    private AliPushHelper mAliPushHelper;
    private CloudPushService pushService = PushServiceFactory.getCloudPushService();;
    private String deviveId = null;
    private static final String TAG = "AliPushModule";

    private static String LocalNotificationReceived	= "localNotificationReceived";
    private static String RemoteNotificationReceived	= "remoteNotificationReceived";
    private static String RemoteNotificationsRegistered	= "remoteNotificationsRegistered";
    private static String AliMessageReceived	= "aliMessageReceived";

    public AliPushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        reactContext.addActivityEventListener(this);
        mReactContext = reactContext;
        mAliPushHelper = new AliPushHelper((Application) reactContext.getApplicationContext());
        registerNotificationsRegistration();
        registerNotificationsReceiveNotification();
    }
    /**
     * 初始化云推送通道
     * @param applicationContext
     */
    private void initCloudChannel(Context applicationContext) {
        PushServiceFactory.init(applicationContext);
        pushService = PushServiceFactory.getCloudPushService();
        pushService.register(applicationContext, new CommonCallback() {
            @Override
            public void onSuccess(String response) {
                Log.d(TAG, "init cloudchannel success");
                deviveId = pushService.getDeviceId();
            }
            @Override
            public void onFailed(String errorCode, String errorMessage) {
                Log.d(TAG, "init cloudchannel failed -- errorcode:" + errorCode + " -- errorMessage:" + errorMessage);
            }
        });
    }
    @Override
    public String getName() {
        return "AliPushManager";
    }

    // removed @Override temporarily just to get it working on different versions of RN
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        onActivityResult(requestCode, resultCode, data);
    }

    // removed @Override temporarily just to get it working on different versions of RN
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        // Ignored, required to implement ActivityEventListener for RN 0.33
    }

    @Override
    public void onNewIntent(Intent intent) {
        Log.d(TAG, "onNewIntent");
        if (intent.hasExtra("notification")) {
            Bundle bundle = intent.getBundleExtra("notification");
            bundle.putBoolean("foreground", false);
            intent.putExtra("notification", bundle);
            notifyNotification(bundle);
//            mJsDelivery.notifyNotification(bundle);
        }
    }

    private void registerNotificationsRegistration() {
        IntentFilter intentFilter = new IntentFilter("RNPushNotificationRegisteredToken");

        mReactContext.registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String token = intent.getStringExtra("token");
                WritableMap params = Arguments.createMap();
                params.putString("deviceToken", token);

                sendEvent(RemoteNotificationsRegistered, params);
            }
        }, intentFilter);
    }

    private void registerNotificationsReceiveNotification() {
        IntentFilter intentFilter = new IntentFilter("RNPushNotificationReceiveNotification");
        mReactContext.registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                notifyNotification(intent.getBundleExtra("notification"));
            }
        }, intentFilter);
    }

    private void notifyNotification(Bundle bundle) {

        WritableMap params = Arguments.createMap();
        Set<String> keys = bundle.keySet();
        for (String key : keys) {
//            Log.d(TAG,"bundle key:"+key);
            Object value = bundle.get(key);
            if (value instanceof String) {
                params.putString(key, bundle.getString(key));
            }
        }
//        params.putBoolean("",true);

        sendEvent(RemoteNotificationReceived, params);
    }

    private void sendEvent(String eventName, Object params) {
        if (mReactContext.hasActiveCatalystInstance()) {
            mReactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, params);
        }
    }

    @ReactMethod
    public void requestPermissions(ReadableMap permissions, final Promise promise) {
        Log.d("requestPermissions", "requestPermissions");
        try {
            if(pushService.getDeviceId() != null){
                promise.resolve(pushService.getDeviceId());
            }else {
                promise.reject("0", "0");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    @ReactMethod
    public void bindAccount(String account, final Promise promise) {
        Log.d(TAG, "bindAccount:" + account);
        if (null != pushService) {
            pushService.bindAccount(account, new CommonCallback() {
                @Override
                public void onSuccess(String s) {
                    Log.d(TAG, "bindAccount success:" + s);
                    promise.resolve("bindAccount success:" + s);
                }

                @Override
                public void onFailed(String errorCode, String errorMessage) {
                    Log.d(TAG, "bindAccount failure:" + errorCode + "," + errorMessage);
                    promise.reject(errorCode, errorMessage);
                }
            });

        }
    }

    @ReactMethod
    public void unbindAccount(final Promise promise) {
        Log.d(TAG, "unbindAccount:");
        if (null != pushService) {
            pushService.unbindAccount(new CommonCallback() {
                @Override
                public void onSuccess(String s) {
                    Log.d(TAG, "unbindAccount success:" + s);
                    promise.resolve("unbindAccount success:" + s);
                }

                @Override
                public void onFailed(String errorCode, String errorMessage) {
                    Log.d(TAG, "unbindAccount failure:" + errorCode + "," + errorMessage);
                    promise.reject(errorCode, errorMessage);
                }
            });

        }
    }

    @ReactMethod
    public void getInitialNotification(Promise promise) {
        WritableMap params = Arguments.createMap();
        Activity activity = getCurrentActivity();
        if (activity != null) {
            Intent intent = activity.getIntent();
            Bundle bundle = intent.getBundleExtra("notification");
            if (bundle != null) {
                bundle.putBoolean("foreground", false);
                Set<String> keys = bundle.keySet();
                for (String key : keys) {
//            Log.d(TAG,"bundle key:"+key);
                    Object value = bundle.get(key);
                    if (value instanceof String) {
                        params.putString(key, bundle.getString(key));
                    }
                }
//                String bundleString = mJsDelivery.convertJSON(bundle);
//                params.putString("dataJSON", bundleString);
            }
        }
        promise.resolve(params);
    }

    @Nullable
    @Override
    public Map<String, Object> getConstants() {
        final Map<String,Object> constants = new HashMap<>();

//        CloudPushService tPushService = PushServiceFactory.getCloudPushService();
////        Log.d(TAG,"pushService:",tPushService)
//        constants.put("DEVICE_ID", tPushService.getDeviceId());


        return constants;
    }
}
