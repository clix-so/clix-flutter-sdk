package so.clix

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.net.toUri

/**
 * NotificationTappedActivity handles interactions triggered by notifications.
 *
 * This activity is primarily responsible for processing notification intents, determining the
 * appropriate action or destination, and handling navigation based on provided data (e.g.,
 * `messageId` and `landingUrl`).
 *
 * Features:
 * - Handles intents received when a notification is tapped.
 * - Extracts and processes data such as `messageId` and `landingUrl` from the intent extras.
 * - Resolves target destinations, such as opening a URL in a browser or launching the app.
 */
class NotificationTappedActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("NotificationTappedActivity", "onCreate called")
        android.util.Log.d("NotificationTappedActivity", "Intent received in onCreate: $intent")
        handleIntent(intent)
        finish()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        android.util.Log.d("NotificationTappedActivity", "onNewIntent called")
        android.util.Log.d("NotificationTappedActivity", "Intent received in onNewIntent: $intent")
        intent?.let { handleIntent(it) }
        finish()
    }

    private fun handleIntent(intent: Intent) {
        android.util.Log.d("NotificationTappedActivity", "Handling intent: $intent")

        val messageId = intent.getStringExtra("messageId")
        val landingUrl = intent.getStringExtra("landingUrl")

        if (messageId == null) {
            android.util.Log.w("NotificationTappedActivity", "messageId is null in intent extras")
        } else {
            android.util.Log.d("NotificationTappedActivity", "Extracted messageId: $messageId")
            // Send event to Flutter via plugin (will be handled when app opens)
            val eventData = mutableMapOf<String, Any>(
                "messageId" to messageId,
                "event" to "PUSH_NOTIFICATION_TAPPED"
            )
            
            if (landingUrl != null) {
                eventData["landingUrl"] = landingUrl
            }
            
            // Store the event data for Flutter to process when it initializes
            val prefs = getSharedPreferences("clix_prefs", MODE_PRIVATE)
            prefs.edit().putString("pending_notification_event", messageId).apply()
        }

        try {
            val destinationIntent = createIntentToOpenUrlOrApp(landingUrl)
            android.util.Log.d("NotificationTappedActivity", "Resolved destinationIntent: $destinationIntent")
            if (destinationIntent != null) {
                android.util.Log.d("NotificationTappedActivity", "Starting activity with intent: $destinationIntent")
                startActivity(destinationIntent)
            } else {
                android.util.Log.w("NotificationTappedActivity", "destinationIntent was null, cannot launch")
            }
        } catch (e: Exception) {
            android.util.Log.e("NotificationTappedActivity", "Failed to open URL or launch app", e)
        }
    }

    private fun createIntentToOpenUrlOrApp(landingUrl: String?): Intent? {
        val uri = landingUrl?.trim()?.takeIf { it.isNotEmpty() }?.toUri()
            ?.also { android.util.Log.d("NotificationTappedActivity", "Parsed landing URL: $it") }

        return if (uri != null) {
            openURLInBrowserIntent(uri)
                .also { android.util.Log.d("NotificationTappedActivity", "Created browser intent: $it") }
        } else {
            packageManager.getLaunchIntentForPackage(packageName)?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                android.util.Log.d("NotificationTappedActivity", "Created launch intent for package: $this")
            }
        }
    }

    private fun openURLInBrowserIntent(uri: Uri): Intent {
        return Intent(Intent.ACTION_VIEW, uri).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
    }
} 