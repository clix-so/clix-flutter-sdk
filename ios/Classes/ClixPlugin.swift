import Flutter
import UIKit
import UserNotifications
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

public class ClixPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clix_flutter", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "clix_flutter/events", binaryMessenger: registrar.messenger())
        
        let instance = ClixPlugin()
        instance.channel = channel
        instance.eventChannel = eventChannel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        registrar.addApplicationDelegate(instance)
    }
    
    // MARK: - Method Call Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "setUserId":
            setUserId(call: call, result: result)
        case "removeUserId":
            removeUserId(result: result)
        case "setUserProperty":
            setUserProperty(call: call, result: result)
        case "setUserProperties":
            setUserProperties(call: call, result: result)
        case "removeUserProperty":
            removeUserProperty(call: call, result: result)
        case "removeUserProperties":
            removeUserProperties(call: call, result: result)
        case "getDeviceId":
            getDeviceId(result: result)
        case "getPushToken":
            getPushToken(result: result)
        case "setLogLevel":
            setLogLevel(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Core Methods
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let projectId = args["projectId"] as? String,
              let apiKey = args["apiKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "projectId and apiKey are required", details: nil))
            return
        }
        
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request permissions and register for notifications
        requestPermissions { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                result(["success": success])
            }
        }
    }
    
    private func setUserId(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "userId is required", details: nil))
            return
        }
        
        UserDefaults.standard.set(userId, forKey: "clix_user_id")
        result(true)
    }
    
    private func removeUserId(result: @escaping FlutterResult) {
        UserDefaults.standard.removeObject(forKey: "clix_user_id")
        result(true)
    }
    
    private func setUserProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] else {
            result(FlutterError(code: "INVALID_ARGS", message: "key and value are required", details: nil))
            return
        }
        
        let prefKey = "clix_user_property_\(key)"
        UserDefaults.standard.set(value, forKey: prefKey)
        result(true)
    }
    
    private func setUserProperties(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let properties = args["properties"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "properties are required", details: nil))
            return
        }
        
        for (key, value) in properties {
            let prefKey = "clix_user_property_\(key)"
            UserDefaults.standard.set(value, forKey: prefKey)
        }
        result(true)
    }
    
    private func removeUserProperty(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "key is required", details: nil))
            return
        }
        
        let prefKey = "clix_user_property_\(key)"
        UserDefaults.standard.removeObject(forKey: prefKey)
        result(true)
    }
    
    private func removeUserProperties(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let keys = args["keys"] as? [String] else {
            result(FlutterError(code: "INVALID_ARGS", message: "keys are required", details: nil))
            return
        }
        
        for key in keys {
            let prefKey = "clix_user_property_\(key)"
            UserDefaults.standard.removeObject(forKey: prefKey)
        }
        result(true)
    }
    
    private func getDeviceId(result: @escaping FlutterResult) {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        result(deviceId)
    }
    
    private func getPushToken(result: @escaping FlutterResult) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "TOKEN_ERROR", message: "Failed to get push token", details: error.localizedDescription))
                    return
                }
                result(token)
            }
        }
        #else
        // Fallback to APNS token
        guard let deviceToken = UIApplication.shared.currentDeviceToken else {
            result(FlutterError(code: "TOKEN_ERROR", message: "Push token not available", details: nil))
            return
        }
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        result(token)
        #endif
    }
    
    private func setLogLevel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let level = args["level"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "level is required", details: nil))
            return
        }
        
        UserDefaults.standard.set(level, forKey: "clix_log_level")
        result(true)
    }
    
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Clix: Notification permission error: \(error)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    // MARK: - Helper Methods
    private func parseNotificationPayload(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        var payload: [String: Any] = [:]
        
        // Copy all notification data
        for (key, value) in userInfo {
            if let stringKey = key as? String {
                payload[stringKey] = value
            }
        }
        
        // Add timestamp
        payload["timestamp"] = Date().timeIntervalSince1970
        
        return payload
    }
}

// MARK: - FlutterStreamHandler
extension ClixPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - UIApplicationDelegate
extension ClixPlugin: UIApplicationDelegate {
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UIApplication.shared.currentDeviceToken = deviceToken
        
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
        
        // Notify Flutter about token
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        eventSink?(["type": "token", "token": token])
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Clix: Failed to register for remote notifications: \(error)")
        eventSink?(["type": "tokenError", "error": error.localizedDescription])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension ClixPlugin {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let payload = parseNotificationPayload(notification.request.content.userInfo)
        eventSink?([
            "type": "notification",
            "event": "foreground",
            "payload": payload
        ])
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = parseNotificationPayload(response.notification.request.content.userInfo)
        eventSink?([
            "type": "notification",
            "event": "tap",
            "payload": payload
        ])
        
        completionHandler()
    }
}

// MARK: - UIApplication Extension for Token Storage
extension UIApplication {
    private static var deviceTokenKey = "ClixDeviceToken"
    
    var currentDeviceToken: Data? {
        get {
            return objc_getAssociatedObject(self, &UIApplication.deviceTokenKey) as? Data
        }
        set {
            objc_setAssociatedObject(self, &UIApplication.deviceTokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}