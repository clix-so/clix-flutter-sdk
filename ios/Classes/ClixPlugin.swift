import Flutter
import UIKit
import UserNotifications

extension FlutterError: Error {}

public class ClixPlugin: NSObject, FlutterPlugin, ClixHostApi {

    private var previousDelegate: UNUserNotificationCenterDelegate?
    private var flutterApi: ClixFlutterApi?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ClixPlugin()
        instance.flutterApi = ClixFlutterApi(binaryMessenger: registrar.messenger())
        ClixHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.addApplicationDelegate(instance)

        DispatchQueue.main.async {
            let notificationCenter = UNUserNotificationCenter.current()
            instance.previousDelegate = notificationCenter.delegate
            notificationCenter.delegate = instance
        }
    }
}

extension ClixPlugin: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let isLocalNotification = !(notification.request.trigger is UNPushNotificationTrigger)
        let hasClixPayload = userInfo["clix"] != nil

        if isLocalNotification {
            completionHandler([.banner, .sound, .badge])
            return
        }

        if let delegate = previousDelegate,
           delegate.responds(to: #selector(userNotificationCenter(_:willPresent:withCompletionHandler:))) {
            if hasClixPayload {
                delegate.userNotificationCenter?(center, willPresent: notification) { _ in
                    completionHandler([])
                }
            } else {
                delegate.userNotificationCenter?(center, willPresent: notification, withCompletionHandler: completionHandler)
            }
        } else {
            completionHandler(hasClixPayload ? [] : [.banner, .sound, .badge])
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let userInfoDict = userInfo.reduce(into: [String?: Any?]()) { $0[$1.key as? String] = $1.value }
        flutterApi?.onNotificationTapped(userInfo: userInfoDict) { _ in }

        if let delegate = previousDelegate,
           delegate.responds(to: #selector(userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            delegate.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
}

