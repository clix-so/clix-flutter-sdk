package so.clix

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.URL

/** ClixMessagingService - Firebase messaging service with Flutter event integration */
class ClixMessagingService : FirebaseMessagingService() {

    companion object {
        private const val CHANNEL_ID = "clix_default"
        private const val CHANNEL_NAME = "Clix Notifications"
        private const val CHANNEL_DESCRIPTION = "Notifications from Clix"
        private var notificationId = 1000
        private const val CONNECT_TIMEOUT_MS = 1000
        private const val READ_TIMEOUT_MS = 3000
        
        // Static reference to plugin for sending events
        var pluginInstance: ClixPlugin? = null
    }

    private val coroutineScope = CoroutineScope(Dispatchers.IO)

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        
        // Store token in shared preferences
        val prefs = getSharedPreferences("clix_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
        
        // Send token refresh event to Flutter
        pluginInstance?.sendEvent("tokenRefresh", mapOf("token" to token))
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // Log message details for debugging
        android.util.Log.d("ClixMessagingService", "Message received from: ${remoteMessage.from}")
        android.util.Log.d("ClixMessagingService", "Message data: ${remoteMessage.data}")
        android.util.Log.d("ClixMessagingService", "Message notification: ${remoteMessage.notification}")
        
        // Create notification payload
        val notificationData = mutableMapOf<String, Any>()
        
        // Add FCM data
        remoteMessage.data.forEach { (key, value) ->
            notificationData[key] = value
            android.util.Log.d("ClixMessagingService", "Data field: $key = $value")
        }
        
        // Parse Clix payload (similar to Android and iOS SDK)
        var title: String? = null
        var body: String? = null
        var imageUrl: String? = null
        var messageId: String? = null
        var landingUrl: String? = null
        
        // Try to parse clix JSON field first (highest priority)
        val clixData = parseClixPayload(remoteMessage.data)
        if (clixData != null) {
            android.util.Log.d("ClixMessagingService", "Successfully parsed Clix payload: $clixData")
            
            // Extract data from Clix payload
            title = clixData.optString("title", null)
            body = clixData.optString("body", null)
            messageId = clixData.optString("message_id", null)
            landingUrl = clixData.optString("landing_url", null)
            imageUrl = clixData.optString("image_url", null)
            
            // Add to notification data
            if (title != null) notificationData["title"] = title
            if (body != null) notificationData["body"] = body
            if (messageId != null) notificationData["messageId"] = messageId
            if (landingUrl != null) notificationData["landingUrl"] = landingUrl
            if (imageUrl != null) notificationData["imageUrl"] = imageUrl
        }
        
        // If title/body not found in Clix payload, try other sources
        if (title == null) {
            title = remoteMessage.data["title"] 
                ?: remoteMessage.data["Title"]
                ?: remoteMessage.data["TITLE"]
                ?: remoteMessage.notification?.title
                ?: "Notification"
            notificationData["title"] = title
        }
        
        if (body == null) {
            body = remoteMessage.data["body"] 
                ?: remoteMessage.data["Body"]
                ?: remoteMessage.data["BODY"]
                ?: remoteMessage.data["message"]
                ?: remoteMessage.data["Message"]
                ?: remoteMessage.notification?.body
                ?: ""
            notificationData["body"] = body
        }
        
        // If image URL not found in Clix payload, try other sources
        if (imageUrl == null) {
            imageUrl = remoteMessage.notification?.imageUrl?.toString()
                ?: remoteMessage.data["image_url"]
                ?: remoteMessage.data["imageUrl"]
                ?: remoteMessage.data["image"]
                
            if (imageUrl != null) {
                notificationData["imageUrl"] = imageUrl
            }
        }
        
        // If message ID not found in Clix payload, try other sources
        if (messageId == null) {
            messageId = remoteMessage.messageId 
                ?: remoteMessage.data["clix_message_id"] 
                ?: remoteMessage.data["message_id"]
                ?: System.currentTimeMillis().toString()
            notificationData["messageId"] = messageId
        }
        
        // If landing URL not found in Clix payload, try other sources
        if (landingUrl == null) {
            landingUrl = remoteMessage.data["clix_landing_url"]
                ?: remoteMessage.data["landing_url"]
                ?: remoteMessage.data["destination_url"]
            
            if (landingUrl != null) {
                notificationData["landingUrl"] = landingUrl
            }
        }
        
        android.util.Log.d("ClixMessagingService", "Final notification data: $notificationData")
        android.util.Log.d("ClixMessagingService", "Final title: $title, body: $body, imageUrl: $imageUrl")
        
        // Send notification received event to Flutter
        pluginInstance?.sendEvent("foregroundNotification", notificationData)
        
        // Show notification
        showNotification(notificationData)
    }

    /**
     * Parse Clix payload from data similar to iOS and Android SDKs
     */
    private fun parseClixPayload(data: Map<String, String>): JSONObject? {
        val clixValue = data["clix"] ?: return null
        android.util.Log.d("ClixMessagingService", "Found clix data: $clixValue")
        
        return try {
            JSONObject(clixValue)
        } catch (e: Exception) {
            android.util.Log.e("ClixMessagingService", "Failed to parse clix data as JSON", e)
            null
        }
    }

    private fun showNotification(payload: Map<String, Any>) {
        createNotificationChannel()
        
        val title = payload["title"]?.toString() ?: "Notification"
        val body = payload["body"]?.toString() ?: ""
        val messageId = payload["messageId"]?.toString() ?: ""
        val imageUrl = payload["imageUrl"]?.toString()
        
        // Create intent for notification tap
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // Add notification data as extras
            payload.forEach { (key, value) ->
                putExtra(key, value.toString())
            }
            // Add special marker to identify notification tap
            putExtra("clix_notification_tapped", true)
            putExtra("clix_message_id", messageId)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 
            messageId.hashCode(), // Use message ID hash for unique pending intent
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(getNotificationIcon())
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
        
        // Add image if available
        if (imageUrl != null) {
            coroutineScope.launch {
                try {
                    val bitmap = loadImageFromUrl(imageUrl)
                    if (bitmap != null) {
                        val bigPictureStyle = NotificationCompat.BigPictureStyle()
                            .bigPicture(bitmap)
                            .setSummaryText(body)
                        
                        // Set large icon and style
                        val updatedBuilder = notificationBuilder
                            .setLargeIcon(bitmap)
                            .setStyle(bigPictureStyle)
                        
                        // Show notification with image
                        showNotificationWithId(messageId.hashCode(), updatedBuilder.build())
                    } else {
                        // Show notification without image if loading failed
                        showNotificationWithId(messageId.hashCode(), notificationBuilder.build())
                    }
                } catch (e: Exception) {
                    // Show notification without image if loading failed
                    showNotificationWithId(messageId.hashCode(), notificationBuilder.build())
                }
            }
        } else {
            // Show notification without image
            showNotificationWithId(messageId.hashCode(), notificationBuilder.build())
        }
    }
    
    private fun showNotificationWithId(id: Int, notification: android.app.Notification) {
        try {
            NotificationManagerCompat.from(this).notify(id, notification)
        } catch (e: Exception) {
            // Handle notification permission issues
        }
    }
    
    private fun getNotificationIcon(): Int {
        // Try to use app icon
        try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            return appInfo.icon
        } catch (e: Exception) {
            // Fallback to Android default icon
            return android.R.drawable.ic_dialog_info
        }
    }
    
    private suspend fun loadImageFromUrl(url: String): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val connection = URL(url).openConnection().apply {
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
            }
            connection.getInputStream().use { inputStream ->
                BitmapFactory.decodeStream(inputStream)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}