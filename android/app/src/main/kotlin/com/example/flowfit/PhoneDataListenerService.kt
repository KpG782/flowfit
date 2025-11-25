package com.example.flowfit

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import org.json.JSONArray

/**
 * Service to receive heart rate data from Galaxy Watch
 * Listens for messages sent via Wearable Data Layer API
 */
class PhoneDataListenerService : WearableListenerService() {
    companion object {
        private const val TAG = "PhoneDataListener"
        private const val MESSAGE_PATH = "/heart_rate"
        private const val BATCH_PATH = "/heart_rate_batch"
        
        // Static event sink for sending data to Flutter
        var eventSink: EventChannel.EventSink? = null
    }
    
    // Handler for posting to main thread
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMessageReceived(messageEvent: MessageEvent) {
        super.onMessageReceived(messageEvent)
        
        Log.i(TAG, "Message received from watch")
        Log.i(TAG, "Path: ${messageEvent.path}")
        
        when (messageEvent.path) {
            MESSAGE_PATH -> {
                handleHeartRateData(messageEvent)
            }
            BATCH_PATH -> {
                handleBatchData(messageEvent)
            }
            else -> {
                Log.w(TAG, "Unknown message path: ${messageEvent.path}")
            }
        }
    }

    private fun handleHeartRateData(messageEvent: MessageEvent) {
        try {
            val jsonData = String(messageEvent.data, Charsets.UTF_8)
            Log.i(TAG, "Heart rate data received: $jsonData")
            
            // Parse JSON string to Map for Flutter
            val jsonMap = parseJsonToMap(jsonData)
            
            // Post to main thread for Flutter communication
            mainHandler.post {
                try {
                    // Send to Flutter via event channel as Map
                    eventSink?.success(jsonMap)
                    Log.i(TAG, "Data sent to Flutter successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending to Flutter", e)
                    eventSink?.error("SEND_ERROR", "Failed to send data to Flutter", e.message)
                }
            }
            
            // Optionally launch the app if not running
            if (eventSink == null) {
                launchMainActivity(jsonData)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling heart rate data", e)
            mainHandler.post {
                eventSink?.error("PARSE_ERROR", "Failed to parse heart rate data", e.message)
            }
        }
    }

    private fun handleBatchData(messageEvent: MessageEvent) {
        try {
            val jsonData = String(messageEvent.data, Charsets.UTF_8)
            Log.i(TAG, "Batch data received: $jsonData")
            
            // Parse JSON string to Map for Flutter
            val jsonMap = parseJsonToMap(jsonData)
            
            // Post to main thread for Flutter communication
            mainHandler.post {
                try {
                    // Send to Flutter via event channel as Map
                    eventSink?.success(jsonMap)
                    Log.i(TAG, "Batch data sent to Flutter successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending batch to Flutter", e)
                    eventSink?.error("SEND_ERROR", "Failed to send batch data to Flutter", e.message)
                }
            }
            
            // Optionally launch the app if not running
            if (eventSink == null) {
                launchMainActivity(jsonData)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling batch data", e)
            mainHandler.post {
                eventSink?.error("PARSE_ERROR", "Failed to parse batch data", e.message)
            }
        }
    }

    private fun launchMainActivity(data: String) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("heart_rate_data", data)
            }
            startActivity(intent)
            Log.i(TAG, "Launched MainActivity with data")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch MainActivity", e)
        }
    }

    /**
     * Parse JSON string to Map for Flutter EventChannel
     */
    private fun parseJsonToMap(jsonString: String): Map<String, Any?> {
        val jsonObject = JSONObject(jsonString)
        return jsonObject.toMap()
    }

    /**
     * Convert JSONObject to Map recursively
     */
    private fun JSONObject.toMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = this.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            var value = this.get(key)
            
            value = when (value) {
                is JSONObject -> value.toMap()
                is JSONArray -> value.toList()
                JSONObject.NULL -> null
                else -> value
            }
            
            map[key] = value
        }
        return map
    }

    /**
     * Convert JSONArray to List recursively
     */
    private fun JSONArray.toList(): List<Any?> {
        val list = mutableListOf<Any?>()
        for (i in 0 until this.length()) {
            var value = this.get(i)
            
            value = when (value) {
                is JSONObject -> value.toMap()
                is JSONArray -> value.toList()
                JSONObject.NULL -> null
                else -> value
            }
            
            list.add(value)
        }
        return list
    }
}
