import UserNotifications
import Foundation
import Firebase
import FirebaseMessaging

/**
 * ClixNotificationServiceExtension
 *
 * A notification service extension that extends UNNotificationServiceExtension to handle
 * rich push notifications with enhanced features such as image processing and analytics tracking.
 *
 * This class provides the following key functionalities:
 * - Processing of incoming push notifications with rich media content
 * - Image download and attachment for rich notifications
 * - Integration with Flutter FCM service for consistent handling
 *
 * Usage:
 * 1. Create a Notification Service Extension target in your iOS app
 * 2. Subclass ClixNotificationServiceExtension in your NotificationService class
 * 3. The extension will automatically handle incoming notifications and process rich content
 *
 * Example:
 * ```swift
 * import clix_flutter
 * 
 * class NotificationService: ClixNotificationServiceExtension {
 *     override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
 *         super.didReceive(request, withContentHandler: contentHandler)
 *     }
 * }
 * ```
 */
@available(iOS 10.0, *)
open class ClixNotificationServiceExtension: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    open override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }
        
        // Process notification with rich media
        processNotificationWithImage(content: bestAttemptContent) { [weak self] updatedContent in
            self?.contentHandler?(updatedContent)
        }
    }
    
    open override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    // MARK: - Rich Media Processing
    
    private func processNotificationWithImage(
        content: UNMutableNotificationContent,
        completion: @escaping (UNNotificationContent) -> Void
    ) {
        let imageURLString = extractImageURL(from: content.userInfo)
        
        guard let imageURLString = imageURLString,
              let imageURL = URL(string: imageURLString) else {
            // No image to process, return original content
            completion(content)
            return
        }
        
        downloadNotificationImage(from: imageURL) { [weak self] attachment in
            if let attachment = attachment {
                content.attachments = [attachment]
            }
            completion(content)
        }
    }
    
    private func extractImageURL(from userInfo: [AnyHashable: Any]) -> String? {
        // Check Clix-specific payload first
        if let clixData = parseClixPayload(from: userInfo),
           let imageURL = clixData["image_url"] as? String {
            return imageURL
        }
        
        // Check direct image_url in userInfo
        if let imageURL = userInfo["image_url"] as? String {
            return imageURL
        }
        
        // Check FCM options
        if let fcmOptions = userInfo["fcm_options"] as? [String: Any],
           let imageURL = fcmOptions["image"] as? String {
            return imageURL
        }
        
        return nil
    }
    
    private func parseClixPayload(from userInfo: [AnyHashable: Any]) -> [String: Any]? {
        guard let clixValue = userInfo["clix"] else { return nil }
        
        if let clixData = clixValue as? [String: Any] {
            return clixData
        }
        
        if let clixString = clixValue as? String,
           let data = clixString.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data) as? [String: Any]
            } catch {
                NSLog("ClixNotificationServiceExtension: Error parsing Clix payload: \\(error)")
            }
        }
        
        return nil
    }
    
    private func downloadNotificationImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let localURL = localURL, error == nil else {
                NSLog("ClixNotificationServiceExtension: Failed to download image: \\(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // Create attachment from downloaded file
            let attachment = self?.createAttachment(from: localURL, identifier: "clix_image")
            completion(attachment)
        }
        task.resume()
    }
    
    private func createAttachment(from url: URL, identifier: String) -> UNNotificationAttachment? {
        // Get file extension from original URL
        let fileExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
        
        // Create a temporary file URL with proper extension
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempFile = tempDirectory.appendingPathComponent("\\(identifier).\\(fileExtension)")
        
        do {
            // Copy file to temp location with proper extension
            if FileManager.default.fileExists(atPath: tempFile.path) {
                try FileManager.default.removeItem(at: tempFile)
            }
            try FileManager.default.copyItem(at: url, to: tempFile)
            
            // Create attachment
            let attachment = try UNNotificationAttachment(identifier: identifier, url: tempFile, options: nil)
            return attachment
        } catch {
            NSLog("ClixNotificationServiceExtension: Failed to create attachment: \\(error)")
            return nil
        }
    }
}