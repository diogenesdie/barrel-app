package com.example.smart_home

import android.net.wifi.WifiManager
import android.net.wifi.WifiInfo
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {

    private val CHANNEL = "wifi_info_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ Trata intents recebidos (ex: TRIGGER_DEVICE_ACTION)
        if (intent?.action == "TRIGGER_DEVICE_ACTION") {
            val deviceId = intent.getStringExtra("device_id")
            // Aqui você pode passar esse deviceId pro Flutter via EventChannel, SharedPreferences ou logs
            println("📡 Trigger recebido para deviceId: $deviceId")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ✅ Canal nativo para expor a frequência Wi-Fi ao Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWifiFrequency" -> {
                        try {
                            val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
                            val info: WifiInfo? = wifiManager.connectionInfo
                            val freq = info?.frequency ?: -1  // Retorna frequência em MHz
                            result.success(freq)
                        } catch (e: Exception) {
                            result.error("WIFI_ERROR", "Falha ao obter frequência do Wi-Fi: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
