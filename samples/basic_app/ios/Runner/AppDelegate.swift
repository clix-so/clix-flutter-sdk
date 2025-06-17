import Flutter
import UIKit
import Firebase
import clix_flutter

@main
@objc class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase before calling super
    FirebaseApp.configure()
    
    // Register generated plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Call ClixAppDelegate's implementation for notification handling
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
