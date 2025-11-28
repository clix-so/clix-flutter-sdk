import Flutter
import UIKit
import UserNotifications

extension FlutterError: Error {}

public class ClixPlugin: NSObject, FlutterPlugin, ClixHostApi {

    private weak var previousDelegate: UNUserNotificationCenterDelegate?
    private var flutterApi: ClixFlutterApi?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ClixPlugin()
        instance.flutterApi = ClixFlutterApi(binaryMessenger: registrar.messenger())
        ClixHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.addApplicationDelegate(instance)
        DispatchQueue.main.async { instance.installDelegate() }
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        installDelegate()
    }

    private func installDelegate() {
        let center = UNUserNotificationCenter.current()
        guard center.delegate !== self else { return }
        previousDelegate = center.delegate
        center.delegate = self
    }
}

extension ClixPlugin: UNUserNotificationCenterDelegate {

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let isLocal = !(notification.request.trigger is UNPushNotificationTrigger)
        let isClix = userInfo["clix"] != nil

        if isLocal {
            completionHandler([.banner, .sound, .badge])
            return
        }

        if let prev = previousDelegate {
            prev.userNotificationCenter?(center, willPresent: notification) { options in
                completionHandler(isClix ? [] : options)
            }
        } else {
            completionHandler(isClix ? [] : [.banner, .sound, .badge])
        }
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let dict = userInfo.reduce(into: [String?: Any?]()) { $0[$1.key as? String] = $1.value }
        flutterApi?.onNotificationTapped(userInfo: dict) { _ in }

        if let prev = previousDelegate {
            prev.userNotificationCenter?(center, didReceive: response, withCompletionHandler: completionHandler)
        } else {
            completionHandler()
        }
    }
}
