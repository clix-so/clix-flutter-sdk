package so.clix

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger

class ClixPlugin: FlutterPlugin {

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Setup Pigeon APIs
        ClixHostApi.setUp(flutterPluginBinding.binaryMessenger, null)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        ClixHostApi.setUp(binding.binaryMessenger, null)
    }

}
