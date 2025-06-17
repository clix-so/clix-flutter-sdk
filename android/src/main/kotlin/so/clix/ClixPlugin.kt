package so.clix

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.annotation.NonNull
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

/** ClixPlugin - Android implementation with notification event handling */
class ClixPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler, PluginRegistry.NewIntentListener {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var activity: Activity? = null

    companion object {
        const val CHANNEL_NAME = "clix_flutter"
        const val EVENT_CHANNEL_NAME = "clix_flutter/events"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
        
        // Register this plugin instance with MessagingService
        ClixMessagingService.pluginInstance = this
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            // Only keep platform-specific methods that MUST be handled natively
            "getDeviceId" -> getDeviceId(result)
            "getPushToken" -> getPushToken(result)
            else -> result.notImplemented()
        }
    }

    // MARK: - Platform-specific methods that require native implementation

    private fun getDeviceId(result: Result) {
        val context = this.context ?: run {
            result.error("NO_CONTEXT", "Context not available", null)
            return
        }

        try {
            val deviceId = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            result.success(deviceId)
        } catch (e: Exception) {
            result.error("DEVICE_ID_ERROR", "Failed to get device ID", e.message)
        }
    }

    private fun getPushToken(result: Result) {
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (!task.isSuccessful) {
                result.error("TOKEN_ERROR", "Failed to get push token", task.exception?.message)
                return@addOnCompleteListener
            }
            
            val token = task.result
            result.success(token)
        }
    }

    // MARK: - Event handling
    
    fun sendEvent(type: String, data: Map<String, Any>) {
        val event = mapOf(
            "type" to type,
            "data" to data
        )
        eventSink?.success(event)
    }

    // MARK: - FlutterPlugin lifecycle

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        // Unregister from MessagingService
        ClixMessagingService.pluginInstance = null
    }

    // MARK: - ActivityAware lifecycle

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        
        // Register for new intent listener
        binding.addOnNewIntentListener(this)
        
        // Check if app was launched by notification tap
        checkForNotificationTap(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        
        // Register for new intent listener again
        binding.addOnNewIntentListener(this)
        
        // Check again for notification tap after config change
        checkForNotificationTap(binding.activity.intent)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
    
    // MARK: - NewIntentListener
    
    override fun onNewIntent(intent: Intent): Boolean {
        checkForNotificationTap(intent)
        return false
    }
    
    private fun checkForNotificationTap(intent: Intent?) {
        intent?.let { launchIntent ->
            if (launchIntent.getBooleanExtra("clix_notification_tapped", false)) {
                // Extract notification data
                val notificationData = mutableMapOf<String, Any>()
                
                // Get all extras that might be notification data
                launchIntent.extras?.let { extras ->
                    for (key in extras.keySet()) {
                        when (val value = extras.get(key)) {
                            is String -> notificationData[key] = value
                            is Boolean -> notificationData[key] = value
                            is Int -> notificationData[key] = value
                            is Long -> notificationData[key] = value
                            is Double -> notificationData[key] = value
                            is Float -> notificationData[key] = value
                            else -> value?.toString()?.let { notificationData[key] = it }
                        }
                    }
                }
                
                // Send notification tapped event to Flutter
                sendEvent("notificationTapped", notificationData)
                
                // Clear the intent extras to avoid processing the same notification multiple times
                launchIntent.removeExtra("clix_notification_tapped")
            }
        }
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}