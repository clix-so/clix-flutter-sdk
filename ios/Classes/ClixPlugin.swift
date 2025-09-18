import Flutter
import UIKit
import Combine

extension FlutterError: Error {}

public class ClixPlugin: NSObject, FlutterPlugin, ClixHostApi {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ClixPlugin()
        ClixHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        registrar.addApplicationDelegate(instance)
    }
}

extension ClixPlugin: UIApplicationDelegate {
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
}
