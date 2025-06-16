package so.clix

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** ClixMessagingService - Simplified Firebase messaging service */
class ClixMessagingService : FirebaseMessagingService() {

    companion object {
        private const val CHANNEL_ID = "clix_default"
        private const val CHANNEL_NAME = "Clix Notifications"
        private const val CHANNEL_DESCRIPTION = "Notifications from Clix"
        private var notificationId = 1000
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        
        // Store token in shared preferences
        val prefs = getSharedPreferences("clix_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("fcm_token", token).apply()
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        // Create notification payload
        val notificationData = mutableMapOf<String, Any>()
        
        // Add FCM data
        remoteMessage.data.forEach { (key, value) ->
            notificationData[key] = value
        }
        
        // Add notification fields
        remoteMessage.notification?.let { notification ->
            notification.title?.let { notificationData["title"] = it }
            notification.body?.let { notificationData["body"] = it }
            notification.imageUrl?.let { notificationData["imageUrl"] = it.toString() }
        }
        
        // Add message ID
        remoteMessage.messageId?.let { notificationData["messageId"] = it }
        
        // Show simple notification
        showNotification(notificationData)
    }

    private fun showNotification(payload: Map<String, Any>) {
        createNotificationChannel()
        
        val title = payload["title"]?.toString() ?: "Notification"
        val body = payload["body"]?.toString() ?: ""
        
        // Create intent for notification tap
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            // Add notification data as extras
            payload.forEach { (key, value) ->
                putExtra(key, value.toString())
            }
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 
            notificationId++, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Default icon
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        
        // Show notification
        with(NotificationManagerCompat.from(this)) {
            notify(notificationId++, notificationBuilder.build())
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = CHANNEL_DESCRIPTION
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}