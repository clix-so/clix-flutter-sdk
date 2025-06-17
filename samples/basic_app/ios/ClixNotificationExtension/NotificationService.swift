import UserNotifications
import clix_flutter

/// ClixNotificationExtension demonstrates how to implement rich push notifications
/// using the Clix Flutter SDK's notification service extension.
///
/// This extension automatically handles:
/// - Image download and attachment for rich notifications
/// - Notification payload processing
/// - Integration with Clix analytics tracking
///
/// To use this in your own app:
/// 1. Create a new Notification Service Extension target in Xcode
/// 2. Replace the generated NotificationService class with this implementation
/// 3. Make sure to add clix_flutter as a dependency to your extension target
/// 4. Update your app's Info.plist to include the extension
class NotificationService: ClixNotificationServiceExtension {
    
    override init() {
        super.init()
        NSLog("[ClixNotificationExtension] Notification service initialized")
    }
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        NSLog("[ClixNotificationExtension] Received notification request: \\(request.identifier)")
        NSLog("[ClixNotificationExtension] Notification payload: \\(request.content.userInfo)")
        
        // Call the parent implementation which handles all the rich notification processing
        super.didReceive(request, withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        NSLog("[ClixNotificationExtension] Service extension time will expire")
        super.serviceExtensionTimeWillExpire()
    }
}