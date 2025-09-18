import Flutter
import UIKit
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase before calling super
    FirebaseApp.configure()
    
    // Register generated plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Call FlutterAppDelegate's implementation
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
