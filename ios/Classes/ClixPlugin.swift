import Flutter
import UIKit

public class ClixPlugin: NSObject, FlutterPlugin {
    
    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let api = ClixPlugin()
        
        // Setup Pigeon APIs
        ClixHostApiSetup.setUp(binaryMessenger: messenger, api: nil)
    }
    
}