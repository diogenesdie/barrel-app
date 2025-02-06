package com.example.smart_home

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if the intent has the action we defined
        if (intent?.action == "TRIGGER_DEVICE_ACTION") {
            val deviceId = intent.getStringExtra("device_id")
            // You can pass this deviceId to your Flutter code or handle it accordingly
        }
    }
}
