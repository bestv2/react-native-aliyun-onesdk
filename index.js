import {
    NativeModules,
    DeviceEventEmitter,
    NativeEventEmitter,
    Platform
} from 'react-native';

const eventsMap = {
    remoteNotificationReceived: 'remoteNotificationReceived',
};

const AliPushManager = NativeModules.AliPushManager;

const AliPush = {};


AliPush.requestPermissions = (permissions=null) => {
    return AliPushManager.requestPermissions(permissions);
};
AliPush.bindAccount = AliPushManager.bindAccount;
AliPush.unbindAccount = AliPushManager.unbindAccount;
AliPush.getInitialNotification = AliPushManager.getInitialNotification;
const AliPushEmitter = new NativeEventEmitter(AliPushManager);
AliPush.on = (event,callback) => {
    const nativeEvent = eventsMap[event];
    if (!nativeEvent) {
        var s = ""
        for(var key in eventsMap){
            s+= key +","
        }
        throw new Error('event must in "'+s);
    }

    const listener = AliPushEmitter.addListener(nativeEvent,callback);
    return listener;
};


module.exports = AliPush;
