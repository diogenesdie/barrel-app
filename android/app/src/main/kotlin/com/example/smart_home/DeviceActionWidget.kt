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
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken
import org.eclipse.paho.client.mqttv3.MqttCallback
import org.eclipse.paho.client.mqttv3.MqttClient
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttException
import org.eclipse.paho.client.mqttv3.MqttMessage
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence

data class Device(val name: String, val route: String, val ip: String = "", val id: String = "")

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
            val ip = intent.getStringExtra("device_ip") ?: ""
            val deviceId = intent.getStringExtra("device_id") ?: ""
            Log.d("DeviceActionWidget", "Button clicked for device: $deviceName")
            Log.d("DeviceActionWidget", "Route: $route")

            val token = "d4f8a7e2-9b3c-4f6a-b5d1-7c9e1a0f2e8c"
            val url = "http://$ip$route" // Replace with your host IP

            makeHttpGetRequest(url, token)

                // MQTT (novo)
            val broker = "tcp://barrel.app.br:1883"
            val topic = "users/sprandel/${deviceId}/command"
            val payload = "trigger"
            publishMqttMessage(broker, topic, payload)
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

    private fun publishMqttMessage(broker: String, topic: String, payload: String) {
        thread {
            try {
                val clientId = "AndroidWidget-" + System.currentTimeMillis()
                val client = MqttClient(broker, clientId, MemoryPersistence())

                val options = MqttConnectOptions().apply {
                    isCleanSession = true
                    userName = "sprandel"      // se necessário
                    password = "1234".toCharArray() // se necessário
                }

                client.connect(options)
                val message = MqttMessage(payload.toByteArray()).apply {
                    qos = 0
                }

                client.publish(topic, message)
                Log.d("DeviceActionWidget", "MQTT message sent to $topic: $payload")
                client.disconnect()
            } catch (e: MqttException) {
                Log.e("DeviceActionWidget", "MQTT publish failed", e)
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
            val ip = deviceObject.getString("ip")
            val id = deviceObject.getString("device_id")

            Log.d("DeviceActionWidget", "Device: $name")
            deviceList.add(Device(name, "/command", ip, id))
        }
    } catch (e: Exception) {
        e.printStackTrace()
    }

    val views = RemoteViews(context.packageName, R.layout.device_action_widget)
    views.removeAllViews(R.id.widget_container)

    var rowView: RemoteViews? = null
    for ((index, device) in deviceList.withIndex()) {
        if (index % 4 == 0) { // A cada 4 dispositivos, cria uma nova linha
            rowView = RemoteViews(context.packageName, R.layout.widget_row)
            views.addView(R.id.widget_container, rowView)
        }

        val buttonView = RemoteViews(context.packageName, R.layout.widget_button_item)
        buttonView.setTextViewText(R.id.device_name, device.name)
        buttonView.setImageViewResource(R.id.device_icon, R.drawable.ic_power)

        val intent = Intent(context, DeviceActionWidget::class.java).apply {
            action = "TRIGGER_DEVICE_ACTION"
            putExtra("device_name", device.name)
            putExtra("device_route", device.route)
            putExtra("device_ip", device.ip)
            putExtra("device_id", device.id)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            device.name.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        buttonView.setOnClickPendingIntent(R.id.device_icon, pendingIntent)
        rowView?.addView(R.id.row_container, buttonView)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
