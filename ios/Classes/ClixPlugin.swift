import Flutter
import UIKit
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

public class ClixPlugin: NSObject, FlutterPlugin {
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
    }
    
    // MARK: - Method Call Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // Only keep platform-specific methods that MUST be handled natively
        case "getDeviceId":
            getDeviceId(result: result)
        case "getPushToken":
            getPushToken(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Platform-specific methods that require native implementation
    
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
        result(FlutterError(code: "TOKEN_ERROR", message: "Firebase Messaging not available", details: nil))
        #endif
    }
    
    // MARK: - Event handling
    
    func sendEvent(type: String, data: [String: Any]) {
        let event: [String: Any] = [
            "type": type,
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