package so.clix

import android.content.Context
import androidx.annotation.NonNull
import com.google.android.gms.tasks.OnCompleteListener
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger

/** ClixPlugin - Minimal Android implementation using Pigeon */
class ClixPlugin: FlutterPlugin, ClixHostApi {
    private var context: Context? = null
    private var flutterApi: ClixFlutterApi? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        // Setup Pigeon APIs
        ClixHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        flutterApi = ClixFlutterApi(flutterPluginBinding.binaryMessenger)
        
        // Register this plugin instance with MessagingService
        ClixMessagingService.pluginInstance = this
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        ClixHostApi.setUp(binding.binaryMessenger, null)
        context = null
        flutterApi = null
        ClixMessagingService.pluginInstance = null
    }

    // MARK: - ClixHostApi Implementation

    override fun getFcmToken(callback: (Result<String>) -> Unit) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener(OnCompleteListener { task ->
            if (!task.isSuccessful) {
                callback(Result.failure(FlutterError("token_error", "Failed to get FCM token: ${task.exception?.message}", null)))
                return@OnCompleteListener
            }

            val token = task.result
            callback(Result.success(token))
        })
    }

    override fun getApnsToken(callback: (Result<String>) -> Unit) {
        // APNS not supported on Android
        callback(Result.failure(FlutterError("unsupported", "APNS tokens are not supported on Android", null)))
    }

    override fun initializeFirebase(callback: (Result<Unit>) -> Unit) {
        // Firebase is initialized automatically on Android
        callback(Result.success(Unit))
    }

    override fun requestPermissions(callback: (Result<Boolean>) -> Unit) {
        // Notification permissions are handled automatically on Android < 13
        // For Android 13+, permissions should be requested from Flutter side
        callback(Result.success(true))
    }

    // MARK: - Internal methods for MessagingService

    fun sendNotificationReceived(title: String, body: String, imageUrl: String?, deepLink: String?, data: Map<String, String>?) {
        val notificationData = NotificationData(
            title = title,
            body = body,
            imageUrl = imageUrl,
            deepLink = deepLink,
            data = data?.mapKeys { it.key }?.mapValues { it.value }
        )
        flutterApi?.onNotificationReceived(notificationData) { }
    }

    fun sendNotificationOpened(title: String, body: String, imageUrl: String?, deepLink: String?, data: Map<String, String>?) {
        val notificationData = NotificationData(
            title = title,
            body = body,
            imageUrl = imageUrl,
            deepLink = deepLink,
            data = data?.mapKeys { it.key }?.mapValues { it.value }
        )
        flutterApi?.onNotificationOpened(notificationData) { }
    }

    fun sendTokenRefresh(token: String) {
        flutterApi?.onTokenRefresh(token) { }
    }

    companion object {
        var pluginInstance: ClixPlugin? = null
    }
}