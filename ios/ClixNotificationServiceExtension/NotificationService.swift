import UserNotifications
import FirebaseMessaging

@available(iOS 10.0, *)
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Process the notification through Firebase Messaging for analytics
        Messaging.serviceExtension().populateNotificationContent(bestAttemptContent, withContentHandler: contentHandler)
        
        // Handle rich media (images, videos, etc.)
        handleRichMedia(request: request, content: bestAttemptContent, contentHandler: contentHandler)
        
        // Modify the notification content as needed
        modifyNotificationContent(content: bestAttemptContent)
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content,
        // otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func handleRichMedia(request: UNNotificationRequest, content: UNMutableNotificationContent, contentHandler: @escaping (UNNotificationContent) -> Void) {
        // Check for image URL in the notification payload
        guard let imageURLString = content.userInfo["clix_image_url"] as? String,
              let imageURL = URL(string: imageURLString) else {
            return
        }
        
        // Download the image
        downloadImage(from: imageURL) { [weak self] attachment in
            guard let self = self else { return }
            
            if let attachment = attachment {
                content.attachments = [attachment]
            }
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil)
                return
            }
            
            // Determine file extension
            let fileExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let fileName = "\(UUID().uuidString).\(fileExtension)"
            let fileURL = tempURL.appendingPathExtension(fileExtension)
            
            do {
                try FileManager.default.moveItem(at: tempURL, to: fileURL)
                let attachment = try UNNotificationAttachment(identifier: fileName, url: fileURL, options: nil)
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func modifyNotificationContent(content: UNMutableNotificationContent) {
        // Add any custom modifications to the notification content
        
        // Example: Add a custom subtitle based on campaign type
        if let campaignId = content.userInfo["clix_campaign_id"] as? String {
            content.subtitle = "Campaign: \(campaignId)"
        }
        
        // Example: Modify the title or body based on user preferences
        // You can add custom logic here based on your needs
        
        // Example: Add custom actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "CLIX_NOTIFICATION",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "CLIX_NOTIFICATION"
    }
}