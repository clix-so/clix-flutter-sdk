package so.clix

import io.flutter.embedding.engine.plugins.FlutterPlugin

class ClixPlugin: FlutterPlugin, ClixHostApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        ClixHostApi.setUp(flutterPluginBinding.binaryMessenger, null)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ClixHostApi.setUp(binding.binaryMessenger, null)
    }
}
