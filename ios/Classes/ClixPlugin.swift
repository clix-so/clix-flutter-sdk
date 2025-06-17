import Flutter
import UIKit
import UserNotifications
import Firebase
import FirebaseMessaging

public class ClixPlugin: NSObject, FlutterPlugin, ClixHostApi {
    private var flutterApi: ClixFlutterApi?
    
    // Notification handling
    private var pendingNotificationData: [String: Any]?
    private var isAppLaunchedFromNotification = false
    
    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let api = ClixPlugin()
        
        // Setup Pigeon APIs
        ClixHostApiSetup.setUp(binaryMessenger: messenger, api: api)
        api.flutterApi = ClixFlutterApi(binaryMessenger: messenger)
        
        // Register with AppDelegate for notification handling
        ClixAppDelegate.registerPlugin(api)
    }
    
    // MARK: - ClixHostApi Implementation
    
    func getFcmToken(completion: @escaping (Result<String, Error>) -> Void) {
        Messaging.messaging().token { token, error in
            if let error = error {
                completion(.failure(PigeonError(code: "token_error", message: "Failed to get FCM token: \(error.localizedDescription)", details: nil)))
            } else if let token = token {
                completion(.success(token))
            } else {
                completion(.failure(PigeonError(code: "token_error", message: "Token is nil", details: nil)))
            }
        }
    }
    
    func getApnsToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let token = Messaging.messaging().apnsToken else {
            completion(.failure(PigeonError(code: "token_not_available", message: "APNS token not available", details: nil)))
            return
        }
        
        // Convert token data to hex string
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        completion(.success(tokenString))
    }
    
    func initializeFirebase(completion: @escaping (Result<Void, Error>) -> Void) {
        // Firebase is initialized in the app's AppDelegate
        // This is just a confirmation that it's ready
        completion(.success(()))
    }
    
    func requestPermissions(completion: @escaping (Result<Bool, Error>) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                completion(.failure(PigeonError(code: "permission_error", message: error.localizedDescription, details: nil)))
            } else {
                completion(.success(granted))
            }
        }
    }
    
    // MARK: - Internal methods for notifications
    
    func sendNotificationReceived(title: String, body: String, imageUrl: String?, deepLink: String?, data: [String: String]?) {
        let notificationData = NotificationData(
            title: title,
            body: body,
            imageUrl: imageUrl,
            deepLink: deepLink,
            data: data
        )
        flutterApi?.onNotificationReceived(notification: notificationData) { _ in }
    }
    
    func sendNotificationOpened(title: String, body: String, imageUrl: String?, deepLink: String?, data: [String: String]?) {
        let notificationData = NotificationData(
            title: title,
            body: body,
            imageUrl: imageUrl,
            deepLink: deepLink,
            data: data
        )
        flutterApi?.onNotificationOpened(notification: notificationData) { _ in }
    }
    
    func sendTokenRefresh(token: String) {
        flutterApi?.onTokenRefresh(token: token) { _ in }
    }
    
    // MARK: - Legacy methods for compatibility with ClixAppDelegate
    
    func handleNotificationReceived(data: [String: Any]) {
        let title = data["title"] as? String ?? "Notification"
        let body = data["body"] as? String ?? ""
        let imageUrl = data["imageUrl"] as? String
        let deepLink = data["deepLink"] as? String ?? data["landingUrl"] as? String
        let stringData = data.compactMapValues { "\($0)" }
        
        sendNotificationReceived(title: title, body: body, imageUrl: imageUrl, deepLink: deepLink, data: stringData)
    }
    
    func handleNotificationOpened(data: [String: Any]) {
        let title = data["title"] as? String ?? "Notification"
        let body = data["body"] as? String ?? ""
        let imageUrl = data["imageUrl"] as? String
        let deepLink = data["deepLink"] as? String ?? data["landingUrl"] as? String
        let stringData = data.compactMapValues { "\($0)" }
        
        sendNotificationOpened(title: title, body: body, imageUrl: imageUrl, deepLink: deepLink, data: stringData)
    }
}