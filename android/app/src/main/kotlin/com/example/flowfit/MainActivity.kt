package com.example.flowfit

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.MotionEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.samsung.wearable_rotary.WearableRotaryPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }
    
    private val CHANNEL = "com.flowfit.watch/data"
    private val EVENT_CHANNEL = "com.flowfit.watch/heartrate"
    private val PERMISSION_REQUEST_CODE = 1001
    
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var heartRateEventSink: EventChannel.EventSink? = null
    private var healthTrackingManager: HealthTrackingManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(Dispatchers.Main)
    
    private var lastHeartRateData: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Make background transparent for round screens (VGV best practice)
        intent.putExtra("background_mode", "transparent")
        super.onCreate(savedInstanceState)
        
        // Initialize health tracking manager
        initializeHealthTracking()
    }
    
    private fun initializeHealthTracking() {
        healthTrackingManager = HealthTrackingManager(
            context = this,
            onHeartRateData = { data ->
                // Convert to map for Flutter
                val dataMap = mapOf(
                    "bpm" to data.bpm,
                    "ibiValues" to data.ibiValues,
                    "timestamp" to data.timestamp,
                    "status" to data.status
                )
                
                // Store last reading
                lastHeartRateData = dataMap
                
                // Send to Flutter via event channel
                mainHandler.post {
                    heartRateEventSink?.success(dataMap)
                }
            },
            onError = { code, message ->
                Log.e(TAG, "Health tracking error: $code - $message")
                mainHandler.post {
                    heartRateEventSink?.error(code, message, null)
                }
            }
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Samsung Health Sensor method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestPermission(result)
                "checkPermission" -> checkPermission(result)
                "connectWatch" -> connectWatch(result)
                "disconnectWatch" -> disconnectWatch(result)
                "isWatchConnected" -> isWatchConnected(result)
                "startHeartRate" -> startHeartRate(result)
                "stopHeartRate" -> stopHeartRate(result)
                "getCurrentHeartRate" -> getCurrentHeartRate(result)
                else -> result.notImplemented()
            }
        }
        
        // Heart rate event channel for streaming data
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    heartRateEventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    heartRateEventSink = null
                }
            }
        )
    }

    /**
     * Request BODY_SENSORS permission from the user
     */
    private fun requestPermission(result: MethodChannel.Result) {
        try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS) 
                == PackageManager.PERMISSION_GRANTED) {
                // Permission already granted
                result.success(true)
            } else {
                // Store the result to respond after permission dialog
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.BODY_SENSORS),
                    PERMISSION_REQUEST_CODE
                )
            }
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to request body sensor permission",
                e.message
            )
        }
    }

    /**
     * Check the current BODY_SENSORS permission status
     */
    private fun checkPermission(result: MethodChannel.Result) {
        try {
            val status = when (ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS)) {
                PackageManager.PERMISSION_GRANTED -> "granted"
                PackageManager.PERMISSION_DENIED -> {
                    // Check if we should show rationale (user denied but can ask again)
                    if (ActivityCompat.shouldShowRequestPermissionRationale(this, Manifest.permission.BODY_SENSORS)) {
                        "denied"
                    } else {
                        // User permanently denied or hasn't been asked yet
                        "denied"
                    }
                }
                else -> "notDetermined"
            }
            result.success(status)
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to check body sensor permission",
                e.message
            )
        }
    }

    /**
     * Handle permission request result
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    /**
     * Connect to Samsung Health services
     */
    private fun connectWatch(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        try {
            val connected = manager.connect()
            result.success(connected)
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to watch", e)
            result.error(
                "CONNECTION_FAILED",
                "Failed to connect: ${e.message}",
                null
            )
        }
    }

    /**
     * Disconnect from Samsung Health services
     */
    private fun disconnectWatch(result: MethodChannel.Result) {
        try {
            healthTrackingManager?.disconnect()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from watch", e)
            result.error(
                "DISCONNECT_ERROR",
                "Failed to disconnect: ${e.message}",
                null
            )
        }
    }

    /**
     * Check if currently connected to Samsung Health services
     */
    private fun isWatchConnected(result: MethodChannel.Result) {
        val connected = healthTrackingManager?.isConnected() ?: false
        result.success(connected)
    }

    /**
     * Start heart rate tracking
     */
    private fun startHeartRate(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        if (!manager.isConnected()) {
            result.error(
                "NOT_CONNECTED",
                "Not connected to Health Tracking Service",
                null
            )
            return
        }
        
        try {
            val started = manager.startTracking()
            result.success(started)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting heart rate tracking", e)
            result.error(
                "TRACKING_ERROR",
                "Failed to start tracking: ${e.message}",
                null
            )
        }
    }

    /**
     * Stop heart rate tracking
     */
    private fun stopHeartRate(result: MethodChannel.Result) {
        try {
            healthTrackingManager?.stopTracking()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping heart rate tracking", e)
            result.error(
                "TRACKING_ERROR",
                "Failed to stop tracking: ${e.message}",
                null
            )
        }
    }

    /**
     * Get the current/last heart rate reading
     */
    private fun getCurrentHeartRate(result: MethodChannel.Result) {
        result.success(lastHeartRateData)
    }

    // Support for rotary input (rotating bezel on Galaxy Watch)
    override fun onGenericMotionEvent(event: MotionEvent?): Boolean {
        return when {
            WearableRotaryPlugin.onGenericMotionEvent(event) -> true
            else -> super.onGenericMotionEvent(event)
        }
    }
    
    /**
     * Handle onDestroy lifecycle event
     * Complete cleanup of resources
     */
    override fun onDestroy() {
        super.onDestroy()
        // Clean up health tracking
        healthTrackingManager?.disconnect()
        healthTrackingManager = null
        // Clean up event sink
        heartRateEventSink = null
    }
}