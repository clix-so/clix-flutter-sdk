package so.clix

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.provider.Settings
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

/** ClixPlugin - Simplified Android implementation matching iOS SDK interface */
class ClixPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var prefs: SharedPreferences? = null

    companion object {
        const val CHANNEL_NAME = "clix_flutter"
        const val EVENT_CHANNEL_NAME = "clix_flutter/events"
        const val PREFS_NAME = "clix_prefs"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        prefs = context?.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "setUserId" -> setUserId(call, result)
            "removeUserId" -> removeUserId(result)
            "setUserProperty" -> setUserProperty(call, result)
            "setUserProperties" -> setUserProperties(call, result)
            "removeUserProperty" -> removeUserProperty(call, result)
            "removeUserProperties" -> removeUserProperties(call, result)
            "getDeviceId" -> getDeviceId(result)
            "getPushToken" -> getPushToken(result)
            "setLogLevel" -> setLogLevel(call, result)
            else -> result.notImplemented()
        }
    }

    // MARK: - Core Methods (matching iOS interface)

    private fun initialize(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val projectId = args?.get("projectId") as? String
        val apiKey = args?.get("apiKey") as? String

        if (projectId == null || apiKey == null) {
            result.error("INVALID_ARGS", "projectId and apiKey are required", null)
            return
        }

        try {
            // Store configuration
            prefs?.edit()?.apply {
                putString("project_id", projectId)
                putString("api_key", apiKey)
                apply()
            }

            // Check notification permissions
            val context = this.context ?: run {
                result.error("NO_CONTEXT", "Context not available", null)
                return
            }

            val notificationManager = NotificationManagerCompat.from(context)
            val areNotificationsEnabled = notificationManager.areNotificationsEnabled()
            
            result.success(mapOf("success" to areNotificationsEnabled))
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Failed to initialize", e.message)
        }
    }

    private fun setUserId(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val userId = args?.get("userId") as? String

        if (userId == null) {
            result.error("INVALID_ARGS", "userId is required", null)
            return
        }

        prefs?.edit()?.putString("clix_user_id", userId)?.apply()
        result.success(true)
    }

    private fun removeUserId(result: Result) {
        prefs?.edit()?.remove("clix_user_id")?.apply()
        result.success(true)
    }

    private fun setUserProperty(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val key = args?.get("key") as? String
        val value = args?.get("value")

        if (key == null || value == null) {
            result.error("INVALID_ARGS", "key and value are required", null)
            return
        }

        val prefKey = "clix_user_property_$key"
        when (value) {
            is String -> prefs?.edit()?.putString(prefKey, value)?.apply()
            is Boolean -> prefs?.edit()?.putBoolean(prefKey, value)?.apply()
            is Int -> prefs?.edit()?.putInt(prefKey, value)?.apply()
            is Long -> prefs?.edit()?.putLong(prefKey, value)?.apply()
            is Float -> prefs?.edit()?.putFloat(prefKey, value)?.apply()
            else -> prefs?.edit()?.putString(prefKey, value.toString())?.apply()
        }
        
        result.success(true)
    }

    private fun setUserProperties(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val properties = args?.get("properties") as? Map<String, Any>

        if (properties == null) {
            result.error("INVALID_ARGS", "properties are required", null)
            return
        }

        val editor = prefs?.edit()
        for ((key, value) in properties) {
            val prefKey = "clix_user_property_$key"
            when (value) {
                is String -> editor?.putString(prefKey, value)
                is Boolean -> editor?.putBoolean(prefKey, value)
                is Int -> editor?.putInt(prefKey, value)
                is Long -> editor?.putLong(prefKey, value)
                is Float -> editor?.putFloat(prefKey, value)
                else -> editor?.putString(prefKey, value.toString())
            }
        }
        editor?.apply()
        
        result.success(true)
    }

    private fun removeUserProperty(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val key = args?.get("key") as? String

        if (key == null) {
            result.error("INVALID_ARGS", "key is required", null)
            return
        }

        val prefKey = "clix_user_property_$key"
        prefs?.edit()?.remove(prefKey)?.apply()
        result.success(true)
    }

    private fun removeUserProperties(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val keys = args?.get("keys") as? List<String>

        if (keys == null) {
            result.error("INVALID_ARGS", "keys are required", null)
            return
        }

        val editor = prefs?.edit()
        for (key in keys) {
            val prefKey = "clix_user_property_$key"
            editor?.remove(prefKey)
        }
        editor?.apply()
        
        result.success(true)
    }

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

    private fun setLogLevel(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any>
        val level = args?.get("level") as? Int

        if (level == null) {
            result.error("INVALID_ARGS", "level is required", null)
            return
        }

        prefs?.edit()?.putInt("clix_log_level", level)?.apply()
        result.success(true)
    }

    // MARK: - Event handling
    
    private fun sendEvent(type: String, data: Map<String, Any>) {
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
    }

    // MARK: - ActivityAware lifecycle

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
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

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}