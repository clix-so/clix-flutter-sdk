import Flutter
import UIKit
import UserNotifications

extension FlutterError: Error {}

public class ClixPlugin: NSObject, FlutterPlugin, ClixHostApi {

    private var previousDelegate: UNUserNotificationCenterDelegate?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ClixPlugin()
        ClixHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.addApplicationDelegate(instance)

        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            instance.previousDelegate = center.delegate
            center.delegate = instance
        }
    }

    private func isClixMessage(_ userInfo: [AnyHashable: Any]) -> Bool {
        userInfo["clix"] != nil
    }
}

extension ClixPlugin: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        if isClixMessage(userInfo) {
            completionHandler([])
            return
        }

        if let previousDelegate = previousDelegate,
           previousDelegate.responds(to: #selector(userNotificationCenter(_:willPresent:withCompletionHandler:))) {
            previousDelegate.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let previousDelegate = previousDelegate,
           previousDelegate.responds(to: #selector(userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            previousDelegate.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
}

extension ClixPlugin: UIApplicationDelegate {
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }

    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
}
