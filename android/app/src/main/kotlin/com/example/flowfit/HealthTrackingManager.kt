package com.example.flowfit

import android.content.Context
import android.util.Log
import com.samsung.android.service.health.tracking.ConnectionListener
import com.samsung.android.service.health.tracking.HealthTracker
import com.samsung.android.service.health.tracking.HealthTrackerException
import com.samsung.android.service.health.tracking.HealthTrackingService
import com.samsung.android.service.health.tracking.data.DataPoint
import com.samsung.android.service.health.tracking.data.HealthTrackerType
import com.samsung.android.service.health.tracking.data.ValueKey

/**
 * Simplified Manager for Samsung Health Tracking Service
 * Handles heart rate tracking and data streaming
 */
class HealthTrackingManager(
    private val context: Context,
    private val onHeartRateData: (HeartRateData) -> Unit,
    private val onError: (String, String?) -> Unit
) {
    companion object {
        private const val TAG = "HealthTrackingManager"
        
        // Heart rate status codes
        private const val HR_STATUS_VALID = 1
        private const val IBI_STATUS_VALID = 0
    }

    private var healthTrackingService: HealthTrackingService? = null
    private var heartRateTracker: HealthTracker? = null
    private var isTracking = false

    /**
     * Connection listener for Samsung Health Tracking Service
     * Implements the proper ConnectionListener interface as per Samsung SDK requirements
     */
    private val connectionListener = object : ConnectionListener {
        override fun onConnectionSuccess() {
            Log.i(TAG, "Health Tracking Service connected successfully")
        }

        override fun onConnectionEnded() {
            Log.i(TAG, "Health Tracking Service connection ended")
            healthTrackingService = null
        }

        override fun onConnectionFailed(error: HealthTrackerException?) {
            val errorMsg = error?.message ?: "Unknown connection error"
            Log.e(TAG, "Health Tracking Service connection failed: $errorMsg")
            onError("CONNECTION_FAILED", errorMsg)
            healthTrackingService = null
        }
    }

    /**
     * Connect to Samsung Health Tracking Service
     */
    fun connect(): Boolean {
        return try {
            Log.i(TAG, "Attempting to connect to Health Tracking Service")
            
            // Create HealthTrackingService with proper ConnectionListener
            healthTrackingService = HealthTrackingService(connectionListener, context)
            
            // Give service time to connect
            Thread.sleep(500)
            
            // Check if heart rate tracking is supported
            val isSupported = hasHeartRateCapability()
            if (isSupported) {
                Log.i(TAG, "Heart rate tracking is supported")
                true
            } else {
                Log.e(TAG, "Heart rate tracking is not supported on this device")
                onError("SENSOR_NOT_SUPPORTED", "Heart rate tracking not available")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception during connection", e)
            onError("CONNECTION_FAILED", e.message)
            false
        }
    }

    /**
     * Check if device supports heart rate tracking
     */
    private fun hasHeartRateCapability(): Boolean {
        val service = healthTrackingService ?: return false
        
        return try {
            val supportedTypes = service.trackingCapability.supportHealthTrackerTypes
            val isSupported = supportedTypes.contains(HealthTrackerType.HEART_RATE_CONTINUOUS)
            Log.d(TAG, "Heart rate continuous tracking supported: $isSupported")
            isSupported
        } catch (e: Exception) {
            Log.e(TAG, "Error checking capabilities", e)
            false
        }
    }

    /**
     * Disconnect from Samsung Health Tracking Service
     */
    fun disconnect() {
        Log.i(TAG, "Disconnecting from Health Tracking Service")
        
        try {
            stopTracking()
            healthTrackingService?.disconnectService()
            healthTrackingService = null
        } catch (e: Exception) {
            Log.e(TAG, "Error during disconnect", e)
        }
    }

    /**
     * Check if currently connected
     */
    fun isConnected(): Boolean {
        return healthTrackingService != null
    }

    /**
     * Start heart rate tracking
     */
    fun startTracking(): Boolean {
        if (isTracking) {
            Log.w(TAG, "Already tracking heart rate")
            return true
        }

        val service = healthTrackingService
        if (service == null) {
            Log.e(TAG, "Cannot start tracking: not connected to service")
            onError("SERVICE_UNAVAILABLE", "Not connected to Health Tracking Service")
            return false
        }

        return try {
            Log.i(TAG, "Starting heart rate tracking")
            
            // Get heart rate tracker
            heartRateTracker = service.getHealthTracker(HealthTrackerType.HEART_RATE_CONTINUOUS)
            
            // Set up event listener
            heartRateTracker?.setEventListener(trackerEventListener)
            
            isTracking = true
            Log.i(TAG, "Heart rate tracking started successfully")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start heart rate tracking", e)
            onError("TRACKING_FAILED", e.message)
            false
        }
    }

    /**
     * Stop heart rate tracking
     */
    fun stopTracking() {
        if (!isTracking) {
            Log.d(TAG, "Not currently tracking")
            return
        }

        try {
            Log.i(TAG, "Stopping heart rate tracking")
            heartRateTracker?.unsetEventListener()
            heartRateTracker = null
            isTracking = false
            Log.i(TAG, "Heart rate tracking stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping heart rate tracking", e)
        }
    }

    /**
     * Event listener for heart rate data
     */
    private val trackerEventListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(dataPoints: MutableList<DataPoint>) {
            for (dataPoint in dataPoints) {
                try {
                    processDataPoint(dataPoint)
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing data point", e)
                }
            }
        }

        override fun onFlushCompleted() {
            Log.d(TAG, "Tracker flush completed")
        }

        override fun onError(trackerError: HealthTracker.TrackerError?) {
            val errorMsg = trackerError?.toString() ?: "Unknown tracker error"
            Log.e(TAG, "Tracker error: $errorMsg")
            onError("TRACKER_ERROR", errorMsg)
        }
    }

    /**
     * Process a single data point from the tracker
     */
    private fun processDataPoint(dataPoint: DataPoint) {
        // Extract heart rate
        val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE) as? Int
        val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS) as? Int
        
        // Extract IBI (inter-beat interval) data
        val ibiList = getValidIbiList(dataPoint)
        
        // Only process if we have valid heart rate or IBI data
        if ((hrStatus == HR_STATUS_VALID && hrValue != null) || ibiList.isNotEmpty()) {
            val heartRateData = HeartRateData(
                bpm = if (hrStatus == HR_STATUS_VALID) hrValue else null,
                ibiValues = ibiList,
                timestamp = System.currentTimeMillis(),
                status = if (hrStatus == HR_STATUS_VALID) "active" else "inactive"
            )
            
            Log.d(TAG, "Heart rate data: ${heartRateData.bpm} bpm, ${ibiList.size} IBI values")
            onHeartRateData(heartRateData)
        }
    }

    /**
     * Extract valid IBI values from data point
     */
    private fun getValidIbiList(dataPoint: DataPoint): List<Int> {
        return try {
            val ibiValues = dataPoint.getValue(ValueKey.HeartRateSet.IBI_LIST) as? IntArray
            val ibiStatuses = dataPoint.getValue(ValueKey.HeartRateSet.IBI_STATUS_LIST) as? IntArray
            
            if (ibiValues == null || ibiStatuses == null) {
                return emptyList()
            }
            
            val validIbiList = mutableListOf<Int>()
            for (i in ibiValues.indices) {
                if (i < ibiStatuses.size && 
                    ibiStatuses[i] == IBI_STATUS_VALID && 
                    ibiValues[i] != 0) {
                    validIbiList.add(ibiValues[i])
                }
            }
            
            validIbiList
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting IBI values", e)
            emptyList()
        }
    }
}

/**
 * Data class for heart rate information
 */
data class HeartRateData(
    val bpm: Int?,
    val ibiValues: List<Int>,
    val timestamp: Long,
    val status: String
)
