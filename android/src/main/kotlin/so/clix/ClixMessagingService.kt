package so.clix

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class ClixMessagingService : FirebaseMessagingService() {
    
    companion object {
        private const val CHANNEL_ID = "clix_notifications"
        private const val CHANNEL_NAME = "Clix Notifications"
        private const val CHANNEL_DESCRIPTION = "Notifications from Clix service"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        // Parse Clix payload following iOS SDK pattern
        val clixPayload = parseClixPayload(remoteMessage.data)
        
        // Track PUSH_NOTIFICATION_RECEIVED event
        clixPayload["messageId"]?.let { messageId ->
            trackNotificationEvent("PUSH_NOTIFICATION_RECEIVED", messageId.toString(), clixPayload)
        }

        // Send message data to Flutter if app is running
        sendMessageToFlutter("pushReceived", clixPayload)

        // Show notification
        showNotification(remoteMessage, clixPayload)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        
        // Send token to Flutter if app is running following iOS SDK pattern
        val tokenData = mapOf(
            "token" to token,
            "type" to "FCM"
        )
        sendMessageToFlutter("tokenReceived", tokenData)
    }

    private fun sendMessageToFlutter(type: String, data: Map<String, Any>) {
        try {
            // This is a simplified approach - in a production app, you might want to
            // use a more sophisticated method to communicate with Flutter
            val intent = Intent("clix_flutter_sdk_message").apply {
                putExtra("type", type)
                putExtra("data", HashMap(data))
            }
            sendBroadcast(intent)
        } catch (e: Exception) {
            // Handle error - app might not be running
        }
    }

    private fun showNotification(remoteMessage: RemoteMessage, clixPayload: Map<String, Any>) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = CHANNEL_DESCRIPTION
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Create intent for when notification is tapped
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            // Add Clix payload to intent following iOS SDK pattern
            clixPayload.forEach { (key, value) ->
                when (value) {
                    is String -> putExtra(key, value)
                    is Int -> putExtra(key, value)
                    is Boolean -> putExtra(key, value)
                    is Long -> putExtra(key, value)
                    is Double -> putExtra(key, value)
                    else -> putExtra(key, value.toString())
                }
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(remoteMessage.notification?.title ?: remoteMessage.data["title"] ?: "Clix")
            .setContentText(remoteMessage.notification?.body ?: remoteMessage.data["body"] ?: "New message")
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)

        // Add Clix payload as extras
        clixPayload.forEach { (key, value) ->
            notificationBuilder.addExtras(android.os.Bundle().apply {
                putString(key, value.toString())
            })
        }

        // Show notification
        notificationManager.notify(0, notificationBuilder.build())
    }

    // Following iOS SDK pattern: Parse "clix" payload from notification
    private fun parseClixPayload(data: Map<String, String>): Map<String, Any> {
        // Try to extract clix payload - following iOS SDK pattern
        data["clix"]?.let { clixData ->
            try {
                // Parse JSON string if present
                return parseJsonString(clixData)
            } catch (e: Exception) {
                // Continue to fallback
            }
        }

        // Fallback: create payload from top-level keys
        val payload = mutableMapOf<String, Any>()

        // Extract standard notification fields
        data["messageId"]?.let { payload["messageId"] = it }
        data["campaignId"]?.let { payload["campaignId"] = it }
        data["userId"]?.let { payload["userId"] = it }
        data["deviceId"]?.let { payload["deviceId"] = it }
        data["trackingId"]?.let { payload["trackingId"] = it }
        data["landingUrl"]?.let { payload["landingUrl"] = it }

        // Extract image URL from multiple possible sources (following iOS SDK pattern)
        data["imageUrl"]?.let { payload["imageUrl"] = it }
            ?: data["image"]?.let { payload["imageUrl"] = it }

        // Add title and body
        data["title"]?.let { payload["title"] = it }
        data["body"]?.let { payload["body"] = it }

        // Add any custom properties
        val customProperties = mutableMapOf<String, Any>()
        val excludedKeys = setOf("messageId", "campaignId", "userId", "deviceId", "trackingId", 
                                "landingUrl", "imageUrl", "title", "body", "clix")
        
        for ((key, value) in data) {
            if (!excludedKeys.contains(key)) {
                customProperties[key] = value
            }
        }
        
        if (customProperties.isNotEmpty()) {
            payload["customProperties"] = customProperties
        }

        return payload
    }

    private fun parseJsonString(jsonString: String): Map<String, Any> {
        // Simple JSON parsing - in production, consider using a proper JSON library
        // For now, this is a basic implementation
        return mapOf<String, Any>() // Placeholder - implement proper JSON parsing
    }

    private fun trackNotificationEvent(eventType: String, messageId: String, payload: Map<String, Any>) {
        val eventData = mutableMapOf<String, Any>(
            "messageId" to messageId,
            "eventType" to eventType,
            "timestamp" to System.currentTimeMillis() / 1000.0
        )

        // Add campaign and tracking information if available
        payload["campaignId"]?.let { eventData["campaignId"] = it }
        payload["trackingId"]?.let { eventData["trackingId"] = it }

        // Send analytics event through broadcast
        try {
            val intent = Intent("clix_flutter_sdk_analytics").apply {
                putExtra("eventData", HashMap(eventData))
            }
            sendBroadcast(intent)
        } catch (e: Exception) {
            // Handle error
        }
    }

    private fun getNotificationIcon(): Int {
        // Try to get the app's launcher icon, fallback to a default
        return try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            appInfo.icon
        } catch (e: Exception) {
            android.R.drawable.ic_dialog_info
        }
    }
}