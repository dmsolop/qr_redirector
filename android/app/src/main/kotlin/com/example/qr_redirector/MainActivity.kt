package com.example.qr_redirector

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "qr_redirector/deep_link"
    private var initialLink: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        android.util.Log.d("MainActivity", "configureFlutterEngine called")
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            android.util.Log.d("MainActivity", "Method call received: ${call.method}")
            when (call.method) {
                "getInitialLink" -> {
                    android.util.Log.d("MainActivity", "getInitialLink called, returning: $initialLink")
                    result.success(initialLink)
                    initialLink = null
                }
                "getLinkStream" -> {
                    // Stream реалізований через onDeepLink метод
                    result.success(null)
                }
                "clearLastProcessedLink" -> {
                    android.util.Log.d("MainActivity", "Clearing last processed link")
                    // Очищаємо поточний intent щоб не обробляти його повторно
                    setIntent(Intent())
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        android.util.Log.d("MainActivity", "onNewIntent called")
        setIntent(intent) // Важливо! Оновлюємо поточний intent
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        android.util.Log.d("MainActivity", "onResume called")
        // Перевіряємо чи є новий intent при поверненні
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val action = intent?.action
        val data: Uri? = intent?.data

        android.util.Log.d("MainActivity", "handleIntent called - action: $action, data: $data")

        if (Intent.ACTION_VIEW == action && data != null) {
            val link = data.toString()
            android.util.Log.d("MainActivity", "Deep link received: $link")
            android.util.Log.d("MainActivity", "methodChannel is null: ${methodChannel == null}")
            
            // Якщо додаток вже запущений, відправляємо deep link в Flutter
            if (methodChannel != null) {
                android.util.Log.d("MainActivity", "Sending deep link to existing Flutter instance")
                methodChannel?.invokeMethod("onDeepLink", link)
            } else {
                android.util.Log.d("MainActivity", "Storing deep link for initial processing")
                // Якщо додаток ще не запущений, зберігаємо для початкової обробки
                initialLink = link
            }
        }
    }
}
