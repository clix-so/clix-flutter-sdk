import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

public class ClixPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    // Token management following iOS SDK pattern
    private var currentFCMToken: String?
    private var currentAPNSToken: Data?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "clix_flutter_sdk", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "clix_flutter_sdk/events", binaryMessenger: registrar.messenger())
        
        let instance = ClixPlugin()
        instance.channel = channel
        instance.eventChannel = eventChannel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        
        // Register for notification handling
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAndRegisterForNotifications":
            requestAndRegisterForNotifications(result: result)
        case "getNotificationSettings":
            getNotificationSettings(result: result)
        case "getFCMToken":
            getFCMToken(result: result)
        case "getAPNSToken":
            getAPNSToken(result: result)
        case "subscribeToTopic":
            subscribeToTopic(call: call, result: result)
        case "unsubscribeFromTopic":
            unsubscribeFromTopic(call: call, result: result)
        case "setNotificationBadge":
            setNotificationBadge(call: call, result: result)
        case "clearNotificationBadge":
            clearNotificationBadge(result: result)
        case "handlePushReceived":
            handlePushReceived(call: call, result: result)
        case "handlePushTapped":
            handlePushTapped(call: call, result: result)
        case "trackNotificationEvent":
            trackNotificationEvent(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Following iOS SDK pattern: requestAndRegisterFornotifications
    private func requestAndRegisterForNotifications(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                if granted {
                    // Register for remote notifications after permission granted
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
                result([
                    "granted": granted,
                    "authorizationStatus": granted ? "authorized" : "denied"
                ])
            }
        }
    }
    
    private func getNotificationSettings(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let settingsDict: [String: Any] = [
                    "authorizationStatus": self.authorizationStatusString(settings.authorizationStatus),
                    "alertSetting": self.notificationSettingString(settings.alertSetting),
                    "badgeSetting": self.notificationSettingString(settings.badgeSetting),
                    "soundSetting": self.notificationSettingString(settings.soundSetting),
                    "criticalAlertSetting": self.notificationSettingString(settings.criticalAlertSetting),
                    "providesAppNotificationSettings": settings.providesAppNotificationSettings
                ]
                result(settingsDict)
            }
        }
    }
    
    private func getFCMToken(result: @escaping FlutterResult) {
        Messaging.messaging().token { token, error in
            if let error = error {
                result(FlutterError(code: "TOKEN_ERROR", message: error.localizedDescription, details: nil))
            } else {
                self.currentFCMToken = token
                result([
                    "token": token ?? NSNull(),
                    "type": "FCM"
                ])
            }
        }
    }
    
    private func getAPNSToken(result: @escaping FlutterResult) {
        if let apnsToken = currentAPNSToken {
            let tokenString = apnsToken.map { String(format: "%02.2hhx", $0) }.joined()
            result([
                "token": tokenString,
                "type": "APNS"
            ])
        } else {
            result([
                "token": NSNull(),
                "type": "APNS"
            ])
        }
    }
    
    private func subscribeToTopic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let topic = arguments["topic"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Topic is required", details: nil))
            return
        }
        
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                result(FlutterError(code: "SUBSCRIPTION_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }
    
    private func unsubscribeFromTopic(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let topic = arguments["topic"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Topic is required", details: nil))
            return
        }
        
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                result(FlutterError(code: "UNSUBSCRIPTION_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
    }
    
    private func setNotificationBadge(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let count = arguments["count"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Count is required", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            result(nil)
        }
    }
    
    private func clearNotificationBadge(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            result(nil)
        }
    }
    
    // Following iOS SDK pattern: handlePushReceived
    private func handlePushReceived(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Notification data is required", details: nil))
            return
        }
        
        // Parse Clix payload following iOS SDK pattern
        let clixPayload = parseClixPayload(from: arguments)
        
        // Track PUSH_NOTIFICATION_RECEIVED event
        if let messageId = clixPayload["messageId"] as? String {
            trackNotificationEvent(eventType: "PUSH_NOTIFICATION_RECEIVED", messageId: messageId, payload: clixPayload)
        }
        
        // Send to Flutter
        sendEvent(name: "pushReceived", data: clixPayload)
        result(nil)
    }
    
    // Following iOS SDK pattern: handlePushTapped
    private func handlePushTapped(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Notification data is required", details: nil))
            return
        }
        
        // Parse Clix payload following iOS SDK pattern
        let clixPayload = parseClixPayload(from: arguments)
        
        // Track PUSH_NOTIFICATION_TAPPED event
        if let messageId = clixPayload["messageId"] as? String {
            trackNotificationEvent(eventType: "PUSH_NOTIFICATION_TAPPED", messageId: messageId, payload: clixPayload)
        }
        
        // Handle deep linking if landingUrl is present
        if let landingUrl = clixPayload["landingUrl"] as? String,
           let url = URL(string: landingUrl) {
            UIApplication.shared.open(url)
        }
        
        // Send to Flutter
        sendEvent(name: "pushTapped", data: clixPayload)
        result(nil)
    }
    
    private func trackNotificationEvent(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let eventType = arguments["eventType"] as? String,
              let messageId = arguments["messageId"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Event type and message ID are required", details: nil))
            return
        }
        
        let payload = arguments["payload"] as? [String: Any] ?? [:]
        trackNotificationEvent(eventType: eventType, messageId: messageId, payload: payload)
        result(nil)
    }
    
    private func trackNotificationEvent(eventType: String, messageId: String, payload: [String: Any]) {
        var eventData: [String: Any] = [
            "messageId": messageId,
            "eventType": eventType,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Add campaign and tracking information if available
        if let campaignId = payload["campaignId"] {
            eventData["campaignId"] = campaignId
        }
        if let trackingId = payload["trackingId"] {
            eventData["trackingId"] = trackingId
        }
        
        // Send analytics event to Flutter for processing
        sendEvent(name: "analyticsEvent", data: eventData)
    }
    
    // MARK: - Helper Methods
    
    // Following iOS SDK pattern: Parse "clix" payload from notification
    private func parseClixPayload(from userInfo: [String: Any]) -> [String: Any] {
        // Try to extract clix payload - following iOS SDK pattern
        if let clixData = userInfo["clix"] {
            if let clixDict = clixData as? [String: Any] {
                return clixDict
            } else if let clixString = clixData as? String,
                      let clixJsonData = clixString.data(using: .utf8),
                      let clixDict = try? JSONSerialization.jsonObject(with: clixJsonData) as? [String: Any] {
                return clixDict
            }
        }
        
        // Fallback: create payload from top-level keys
        var payload: [String: Any] = [:]
        
        // Extract standard notification fields
        if let messageId = userInfo["messageId"] as? String {
            payload["messageId"] = messageId
        }
        if let campaignId = userInfo["campaignId"] as? String {
            payload["campaignId"] = campaignId
        }
        if let userId = userInfo["userId"] as? String {
            payload["userId"] = userId
        }
        if let deviceId = userInfo["deviceId"] as? String {
            payload["deviceId"] = deviceId
        }
        if let trackingId = userInfo["trackingId"] as? String {
            payload["trackingId"] = trackingId
        }
        if let landingUrl = userInfo["landingUrl"] as? String {
            payload["landingUrl"] = landingUrl
        }
        
        // Extract image URL from multiple possible sources (following iOS SDK pattern)
        if let imageUrl = userInfo["imageUrl"] as? String {
            payload["imageUrl"] = imageUrl
        } else if let fcmOptions = userInfo["fcm_options"] as? [String: Any],
                  let image = fcmOptions["image"] as? String {
            payload["imageUrl"] = image
        } else if let image = userInfo["image"] as? String {
            payload["imageUrl"] = image
        }
        
        // Add title and body
        if let title = userInfo["title"] as? String {
            payload["title"] = title
        }
        if let body = userInfo["body"] as? String {
            payload["body"] = body
        }
        
        // Add any custom properties
        var customProperties: [String: Any] = [:]
        for (key, value) in userInfo {
            if !["messageId", "campaignId", "userId", "deviceId", "trackingId", "landingUrl", "imageUrl", "title", "body", "clix", "aps", "fcm_options"].contains(key) {
                customProperties[key] = value
            }
        }
        if !customProperties.isEmpty {
            payload["customProperties"] = customProperties
        }
        
        return payload
    }
    
    private func authorizationStatusString(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown"
        }
    }
    
    private func notificationSettingString(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "notSupported"
        case .disabled: return "disabled"
        case .enabled: return "enabled"
        @unknown default: return "unknown"
        }
    }
    
    private func sendEvent(name: String, data: [String: Any]) {
        let event: [String: Any] = [
            "type": name,
            "data": data
        ]
        eventSink?(event)
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

// MARK: - FlutterApplicationLifeCycleDelegate

extension ClixPlugin: FlutterApplicationLifeCycleDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Set up FCM delegate
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Store APNS token following iOS SDK pattern
        currentAPNSToken = deviceToken
        
        // Set APNS token on Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        
        // Send token event to Flutter
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        sendEvent(name: "tokenReceived", data: [
            "token": tokenString,
            "type": "APNS"
        ])
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Send error event to Flutter
        sendEvent(name: "tokenError", data: [
            "error": error.localizedDescription,
            "type": "APNS"
        ])
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle background notifications following iOS SDK pattern
        let clixPayload = parseClixPayload(from: userInfo as? [String: Any] ?? [:])
        
        // Track received event
        if let messageId = clixPayload["messageId"] as? String {
            trackNotificationEvent(eventType: "PUSH_NOTIFICATION_RECEIVED", messageId: messageId, payload: clixPayload)
        }
        
        sendEvent(name: "pushReceived", data: clixPayload)
        completionHandler(.newData)
    }
}

// MARK: - MessagingDelegate

extension ClixPlugin: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        // Store FCM token following iOS SDK pattern
        currentFCMToken = token
        
        let tokenData: [String: Any] = [
            "token": token,
            "type": "FCM"
        ]
        sendEvent(name: "tokenReceived", data: tokenData)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension ClixPlugin: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        let clixPayload = parseClixPayload(from: userInfo as? [String: Any] ?? [:])
        
        // Track received event following iOS SDK pattern
        if let messageId = clixPayload["messageId"] as? String {
            trackNotificationEvent(eventType: "PUSH_NOTIFICATION_RECEIVED", messageId: messageId, payload: clixPayload)
        }
        
        sendEvent(name: "pushReceived", data: clixPayload)
        
        // Show notification in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let clixPayload = parseClixPayload(from: userInfo as? [String: Any] ?? [:])
        
        // Track tapped event following iOS SDK pattern
        if let messageId = clixPayload["messageId"] as? String {
            trackNotificationEvent(eventType: "PUSH_NOTIFICATION_TAPPED", messageId: messageId, payload: clixPayload)
        }
        
        // Handle deep linking if landingUrl is present
        if let landingUrl = clixPayload["landingUrl"] as? String,
           let url = URL(string: landingUrl) {
            UIApplication.shared.open(url)
        }
        
        sendEvent(name: "pushTapped", data: clixPayload)
        completionHandler()
    }
}