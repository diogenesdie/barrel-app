package com.example.smart_home

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.util.Log
import java.net.HttpURLConnection
import java.net.URL
import kotlin.concurrent.thread
import org.json.JSONArray
import org.json.JSONObject

data class Device(val name: String, val route: String)

/**
 * Implementation of App Widget functionality.
 */
class DeviceActionWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == "TRIGGER_DEVICE_ACTION") {
            val deviceName = intent.getStringExtra("device_name") ?: return
            val route = intent.getStringExtra("device_route") ?: return
            Log.d("DeviceActionWidget", "Button clicked for device: $deviceName")
            Log.d("DeviceActionWidget", "Route: $route")

            val token = "d4f8a7e2-9b3c-4f6a-b5d1-7c9e1a0f2e8c"
            val url = "http://192.140.33.83:8081$route" // Replace with your host IP

            makeHttpGetRequest(url, token)
        }
    }

    private fun makeHttpGetRequest(urlString: String, token: String) {
        Log.d("DeviceActionWidget", "Making HTTP GET request to: $urlString")
        thread {
            try {
                val url = URL(urlString)
                val connection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.setRequestProperty("Authorization", "Bearer $token")

                val responseCode = connection.responseCode
                Log.d("DeviceActionWidget", "HTTP Response Code: $responseCode")

                connection.inputStream.bufferedReader().use {
                    Log.d("DeviceActionWidget", "Response: ${it.readText()}")
                }

                connection.disconnect()
            } catch (e: Exception) {
                Log.e("DeviceActionWidget", "HTTP Request failed", e)
            }
        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    val jsonDevices = sharedPreferences.getString("flutter.devices", "[]") // Get stored JSON array
    Log.d("DeviceActionWidget", "Devices: $jsonDevices")

    val deviceList = mutableListOf<Device>()
    try {
        val jsonArray = JSONArray(jsonDevices)
        for (i in 0 until jsonArray.length()) {
            val deviceObject = jsonArray.getJSONObject(i)
            val name = deviceObject.getString("name")
            val controlRoute = deviceObject.getJSONArray("actions").getJSONObject(0).getString("route")

            Log.d("DeviceActionWidget", "Device: $name")
            deviceList.add(Device(name, controlRoute))
        }
    } catch (e: Exception) {
        e.printStackTrace()
    }

    val views = RemoteViews(context.packageName, R.layout.device_action_widget)

    // Remove all previous buttons
    views.removeAllViews(R.id.widget_container)

    for (device in deviceList) {
        val buttonView = RemoteViews(context.packageName, R.layout.widget_button_item)
        buttonView.setTextViewText(R.id.device_name, device.name)

        // Set the icon based on the device type
        val iconResId = R.drawable.ic_power
        buttonView.setImageViewResource(R.id.device_icon, iconResId)

        val intent = Intent(context, DeviceActionWidget::class.java).apply {
            action = "TRIGGER_DEVICE_ACTION"
            putExtra("device_name", device.name)
            putExtra("device_route", device.route)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            device.name.hashCode(), // Unique request code for each device
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        buttonView.setOnClickPendingIntent(R.id.device_icon, pendingIntent)
        views.addView(R.id.widget_container, buttonView)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
