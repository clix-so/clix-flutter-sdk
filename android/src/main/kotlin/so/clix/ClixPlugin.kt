package so.clix

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** ClixPlugin */
class ClixPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var activity: Activity? = null
    
    // Token management following iOS SDK pattern
    private var currentFCMToken: String? = null

    companion object {
        const val CHANNEL_NAME = "clix_flutter_sdk"
        const val EVENT_CHANNEL_NAME = "clix_flutter_sdk/events"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "requestAndRegisterForNotifications" -> {
                requestAndRegisterForNotifications(result)
            }
            "getNotificationSettings" -> {
                getNotificationSettings(result)
            }
            "getFCMToken" -> {
                getFCMToken(result)
            }
            "subscribeToTopic" -> {
                subscribeToTopic(call, result)
            }
            "unsubscribeFromTopic" -> {
                unsubscribeFromTopic(call, result)
            }
            "setNotificationBadge" -> {
                setNotificationBadge(call, result)
            }
            "clearNotificationBadge" -> {
                clearNotificationBadge(result)
            }
            "handlePushReceived" -> {
                handlePushReceived(call, result)
            }
            "handlePushTapped" -> {
                handlePushTapped(call, result)
            }
            "trackNotificationEvent" -> {
                trackNotificationEvent(call, result)
            }
            "openNotificationSettings" -> {
                openNotificationSettings(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // Following iOS SDK pattern: requestAndRegisterForNotifications
    private fun requestAndRegisterForNotifications(result: Result) {
        val context = this.context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        val notificationManager = NotificationManagerCompat.from(context)
        val areNotificationsEnabled = notificationManager.areNotificationsEnabled()
        
        // For Android 13+, permission should be requested by Flutter app
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !areNotificationsEnabled) {
            result.success(mapOf(
                "granted" to false,
                "authorizationStatus" to "denied",
                "needsPermissionRequest" to true
            ))
        } else {
            result.success(mapOf(
                "granted" to areNotificationsEnabled,
                "authorizationStatus" to if (areNotificationsEnabled) "authorized" else "denied",
                "needsPermissionRequest" to false
            ))
        }
    }

    private fun getNotificationSettings(result: Result) {
        val context = this.context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        val notificationManager = NotificationManagerCompat.from(context)
        val areNotificationsEnabled = notificationManager.areNotificationsEnabled()

        val settings = mapOf(
            "authorizationStatus" to if (areNotificationsEnabled) "authorized" else "denied",
            "alertSetting" to if (areNotificationsEnabled) "enabled" else "disabled",
            "badgeSetting" to if (areNotificationsEnabled) "enabled" else "disabled",
            "soundSetting" to if (areNotificationsEnabled) "enabled" else "disabled",
            "criticalAlertSetting" to "notSupported",
            "providesAppNotificationSettings" to true
        )

        result.success(settings)
    }

    private fun getFCMToken(result: Result) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                result.error("TOKEN_ERROR", "Failed to get FCM token", task.exception?.message)
                return@addOnCompleteListener
            }

            val token = task.result
            currentFCMToken = token
            result.success(mapOf(
                "token" to token,
                "type" to "FCM"
            ))
        }
    }

    private fun subscribeToTopic(call: MethodCall, result: Result) {
        val topic = call.argument<String>("topic")
        if (topic == null) {
            result.error("INVALID_ARGUMENTS", "Topic is required", null)
            return
        }

        FirebaseMessaging.getInstance().subscribeToTopic(topic)
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    result.success(null)
                } else {
                    result.error("SUBSCRIPTION_ERROR", "Failed to subscribe to topic", task.exception?.message)
                }
            }
    }

    private fun unsubscribeFromTopic(call: MethodCall, result: Result) {
        val topic = call.argument<String>("topic")
        if (topic == null) {
            result.error("INVALID_ARGUMENTS", "Topic is required", null)
            return
        }

        FirebaseMessaging.getInstance().unsubscribeFromTopic(topic)
            .addOnCompleteListener { task ->
                if (task.isSuccessful) {
                    result.success(null)
                } else {
                    result.error("UNSUBSCRIPTION_ERROR", "Failed to unsubscribe from topic", task.exception?.message)
                }
            }
    }

    private fun setNotificationBadge(call: MethodCall, result: Result) {
        val count = call.argument<Int>("count")
        if (count == null) {
            result.error("INVALID_ARGUMENTS", "Count is required", null)
            return
        }

        // Android doesn't have a built-in badge system like iOS
        // This would require a third-party library or launcher-specific implementation
        // For now, we'll just acknowledge the call
        result.success(null)
    }

    private fun clearNotificationBadge(result: Result) {
        // Android doesn't have a built-in badge system like iOS
        result.success(null)
    }

    // Following iOS SDK pattern: handlePushReceived
    private fun handlePushReceived(call: MethodCall, result: Result) {
        val notificationData = call.arguments as? Map<String, Any>
        if (notificationData == null) {
            result.error("INVALID_ARGUMENTS", "Notification data is required", null)
            return
        }

        // Parse Clix payload following iOS SDK pattern
        val clixPayload = parseClixPayload(notificationData)
        
        // Track PUSH_NOTIFICATION_RECEIVED event
        clixPayload["messageId"]?.let { messageId ->
            trackNotificationEvent("PUSH_NOTIFICATION_RECEIVED", messageId.toString(), clixPayload)
        }

        // Send to Flutter
        sendEvent("pushReceived", clixPayload)
        result.success(null)
    }

    // Following iOS SDK pattern: handlePushTapped
    private fun handlePushTapped(call: MethodCall, result: Result) {
        val notificationData = call.arguments as? Map<String, Any>
        if (notificationData == null) {
            result.error("INVALID_ARGUMENTS", "Notification data is required", null)
            return
        }

        // Parse Clix payload following iOS SDK pattern
        val clixPayload = parseClixPayload(notificationData)
        
        // Track PUSH_NOTIFICATION_TAPPED event
        clixPayload["messageId"]?.let { messageId ->
            trackNotificationEvent("PUSH_NOTIFICATION_TAPPED", messageId.toString(), clixPayload)
        }

        // Handle deep linking if landingUrl is present
        clixPayload["landingUrl"]?.let { landingUrl ->
            try {
                val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(landingUrl.toString()))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context?.startActivity(intent)
            } catch (e: Exception) {
                // Handle error if URL is invalid or no app can handle it
            }
        }

        // Send to Flutter
        sendEvent("pushTapped", clixPayload)
        result.success(null)
    }

    private fun trackNotificationEvent(call: MethodCall, result: Result) {
        val eventType = call.argument<String>("eventType")
        val messageId = call.argument<String>("messageId")
        val payload = call.argument<Map<String, Any>>("payload") ?: emptyMap()
        
        if (eventType == null || messageId == null) {
            result.error("INVALID_ARGUMENTS", "Event type and message ID are required", null)
            return
        }

        trackNotificationEvent(eventType, messageId, payload)
        result.success(null)
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

        // Send analytics event to Flutter for processing
        sendEvent("analyticsEvent", eventData)
    }

    private fun openNotificationSettings(result: Result) {
        val context = this.context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent().apply {
                    action = "android.settings.APP_NOTIFICATION_SETTINGS"
                    putExtra("android.provider.extra.APP_PACKAGE", context.packageName)
                }
            } else {
                Intent().apply {
                    action = "android.settings.APPLICATION_DETAILS_SETTINGS"
                    data = android.net.Uri.fromParts("package", context.packageName, null)
                }
            }
            
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("OPEN_SETTINGS_ERROR", "Failed to open notification settings", e.message)
        }
    }

    // Following iOS SDK pattern: Parse "clix" payload from notification
    private fun parseClixPayload(userInfo: Map<String, Any>): Map<String, Any> {
        // Try to extract clix payload - following iOS SDK pattern
        userInfo["clix"]?.let { clixData ->
            when (clixData) {
                is Map<*, *> -> {
                    @Suppress("UNCHECKED_CAST")
                    return clixData as Map<String, Any>
                }
                is String -> {
                    try {
                        // Parse JSON string
                        return parseJsonString(clixData)
                    } catch (e: Exception) {
                        // Continue to fallback
                    }
                }
            }
        }

        // Fallback: create payload from top-level keys
        val payload = mutableMapOf<String, Any>()

        // Extract standard notification fields
        userInfo["messageId"]?.let { payload["messageId"] = it }
        userInfo["campaignId"]?.let { payload["campaignId"] = it }
        userInfo["userId"]?.let { payload["userId"] = it }
        userInfo["deviceId"]?.let { payload["deviceId"] = it }
        userInfo["trackingId"]?.let { payload["trackingId"] = it }
        userInfo["landingUrl"]?.let { payload["landingUrl"] = it }

        // Extract image URL from multiple possible sources (following iOS SDK pattern)
        userInfo["imageUrl"]?.let { payload["imageUrl"] = it }
            ?: userInfo["image"]?.let { payload["imageUrl"] = it }

        // Add title and body
        userInfo["title"]?.let { payload["title"] = it }
        userInfo["body"]?.let { payload["body"] = it }

        // Add any custom properties
        val customProperties = mutableMapOf<String, Any>()
        val excludedKeys = setOf("messageId", "campaignId", "userId", "deviceId", "trackingId", 
                                "landingUrl", "imageUrl", "title", "body", "clix")
        
        for ((key, value) in userInfo) {
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

    private fun sendEvent(type: String, data: Map<String, Any>) {
        val event = mapOf(
            "type" to type,
            "data" to data
        )
        eventSink?.success(event)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        
        // Handle intent from notification tap
        handleInitialIntent(binding.activity.intent)
        
        // Set up new intent listener
        binding.addOnNewIntentListener { intent ->
            handleInitialIntent(intent)
            false
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun handleInitialIntent(intent: Intent?) {
        intent?.extras?.let { extras ->
            val notificationData = mutableMapOf<String, Any>()
            for (key in extras.keySet()) {
                extras.get(key)?.let { value ->
                    notificationData[key] = value
                }
            }
            
            if (notificationData.isNotEmpty()) {
                sendEvent("notificationTapped", notificationData)
            }
        }
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}