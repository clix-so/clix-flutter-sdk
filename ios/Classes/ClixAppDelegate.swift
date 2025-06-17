import Flutter
import UIKit
import UserNotifications
import Firebase
import FirebaseCore
import FirebaseMessaging

/**
 * ClixAppDelegate (Simplified)
 *
 * A minimal helper class that provides essential Firebase integration for iOS push notifications.
 * Notification tap handling and URL processing are now handled in Flutter via FCMService.
 *
 * Features:
 * - Firebase Messaging delegate setup
 * - APNS token registration
 * - Minimal notification delegate forwarding to Flutter
 *
 * Usage:
 * ```swift
 * @main
 * class AppDelegate: ClixAppDelegate {
 *     override func application(
 *         _ application: UIApplication,
 *         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
 *     ) -> Bool {
 *         // Configure Firebase before calling super
 *         FirebaseApp.configure()
 *         
 *         return super.application(application, didFinishLaunchingWithOptions: launchOptions)
 *     }
 * }
 * ```
 */
@available(iOS 10.0, *)
open class ClixAppDelegate: FlutterAppDelegate {
    
    // MARK: - UIApplicationDelegate
    
    open override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        // Call super to ensure Flutter initialization
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    open override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Forward to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        NSLog("ClixAppDelegate: APNS token registered with Firebase Messaging")
        
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    open override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NSLog("ClixAppDelegate: Failed to register for remote notifications: \\(error)")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
}

// MARK: - UNUserNotificationCenterDelegate
@available(iOS 10.0, *)
extension ClixAppDelegate: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        NSLog("ClixAppDelegate: Notification received in foreground")
        
        let userInfo = notification.request.content.userInfo
        
        // Send to plugin for Flutter processing
        ClixAppDelegate.pluginInstance?.processNotificationReceived(userInfo: userInfo)
        
        // Show notification in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NSLog("ClixAppDelegate: Notification tapped")
        
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        ClixAppDelegate.pluginInstance?.processNotificationTapped(userInfo: userInfo)
        
        // Handle landing URL
        if let landingURL = extractLandingURL(from: userInfo) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.openURLSafely(landingURL)
            }
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
@available(iOS 10.0, *)
extension ClixAppDelegate: MessagingDelegate {
    
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            NSLog("ClixAppDelegate: FCM registration token is nil")
            return
        }
        
        NSLog("ClixAppDelegate: FCM token received: \\(token.prefix(20))...")
        
        // Token is automatically handled by Flutter FCM service
        // No additional processing needed here
    }
}