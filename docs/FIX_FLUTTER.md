package com.example.pulsify

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.samsung.android.service.health.tracking.ConnectionListener
import com.samsung.android.service.health.tracking.HealthTracker
import com.samsung.android.service.health.tracking.HealthTrackerException
import com.samsung.android.service.health.tracking.HealthTrackingService
import com.samsung.android.service.health.tracking.data.DataPoint
import com.samsung.android.service.health.tracking.data.HealthTrackerType
import com.samsung.android.service.health.tracking.data.ValueKey
import io.flutter.plugin.common.MethodChannel

private const val TAG = "HealthTrackingManager"

class HealthTrackingManager(
    private val context: Context,
    private val result: MethodChannel.Result
) {
    
    private var healthTrackingService: HealthTrackingService? = null
    private var heartRateTracker: HealthTracker? = null
    private var isConnecting = false
    
    companion object {
        // Required permission
        const val BODY_SENSORS_PERMISSION = "android.permission.BODY_SENSORS"
        const val HEALTH_READ_HR_PERMISSION = "android.permission.health.READ_HEART_RATE"
    }
    
    // ============ PERMISSION HANDLING ============
    
    fun checkPermission(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            HEALTH_READ_HR_PERMISSION
        } else {
            BODY_SENSORS_PERMISSION
        }
        
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
        
        Log.i(TAG, "📋 Permission check: $permission = ${if (hasPermission) "GRANTED" else "DENIED"}")
        return hasPermission
    }
    
    fun getRequiredPermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            HEALTH_READ_HR_PERMISSION
        } else {
            BODY_SENSORS_PERMISSION
        }
    }
    
    // ============ CONNECTION HANDLING ============
    
    fun connectToHealthTrackingService() {
        if (isConnecting) {
            Log.w(TAG, "⚠️ Already attempting to connect, ignoring duplicate request")
            return
        }
        
        // CRITICAL: Check permission FIRST
        if (!checkPermission()) {
            Log.e(TAG, "❌ BODY_SENSORS permission not granted!")
            result.error(
                "PERMISSION_DENIED",
                "Health sensor permission not granted. Request permission first.",
                null
            )
            return
        }
        
        isConnecting = true
        Log.i(TAG, "🔄 Attempting to connect to Health Tracking Service")
        
        val connectionListener = object : ConnectionListener {
            override fun onConnectionSuccess() {
                Log.i(TAG, "✅ Connected to Health Tracking Service")
                isConnecting = false
                healthTrackingService = HealthTrackingService(connectionListener, context)
                
                // Verify capabilities
                val capabilities = healthTrackingService?.trackingCapability?.supportHealthTrackerTypes
                Log.i(TAG, "📊 Available trackers: ${capabilities?.joinToString()}")
                
                result.success(mapOf(
                    "connected" to true,
                    "message" to "Connected to Health Tracking Service",
                    "capabilities" to capabilities?.map { it.name }
                ))
            }

            override fun onConnectionEnded() {
                Log.w(TAG, "⚠️ Connection ended")
                isConnecting = false
                result.error(
                    "CONNECTION_ENDED",
                    "Health Tracking Service connection ended",
                    null
                )
            }

            override fun onConnectionFailed(exception: HealthTrackerException?) {
                Log.e(TAG, "❌ Connection failed: ${exception?.message}")
                isConnecting = false
                
                val errorMessage = when (exception?.errorCode) {
                    HealthTrackerException.OLD_PLATFORM_VERSION -> 
                        "Device platform too old"
                    HealthTrackerException.PACKAGE_NAME_MISMATCH -> 
                        "Package name mismatch"
                    HealthTrackerException.SDK_POLICY_ERROR -> 
                        "SDK policy error - check Samsung Health permissions"
                    HealthTrackerException.SDK_NOT_SUPPORTED_ERROR -> 
                        "SDK not supported on this device"
                    else -> 
                        exception?.message ?: "Unknown error"
                }
                
                result.error(
                    "CONNECTION_FAILED",
                    errorMessage,
                    mapOf("errorCode" to exception?.errorCode)
                )
            }
        }

        try {
            Log.i(TAG, "⏳ Waiting for connection callback...")
            healthTrackingService = HealthTrackingService(connectionListener, context)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during connection: ${e.message}")
            isConnecting = false
            result.error(
                "CONNECTION_EXCEPTION",
                e.message ?: "Unknown exception",
                null
            )
        }
    }
    
    // ============ HEART RATE TRACKING ============
    
    fun startHeartRateTracking(eventSink: FlutterEventChannel.EventSink) {
        if (!checkPermission()) {
            eventSink.error(
                "PERMISSION_DENIED",
                "Health sensor permission not granted",
                null
            )
            return
        }
        
        if (healthTrackingService == null) {
            eventSink.error(
                "NOT_CONNECTED",
                "Not connected to Health Tracking Service",
                null
            )
            return
        }
        
        try {
            heartRateTracker = healthTrackingService?.getHealthTracker(
                HealthTrackerType.HEART_RATE_CONTINUOUS
            )
            
            val trackerEventListener = object : HealthTracker.TrackerEventListener {
                override fun onDataReceived(dataPoints: MutableList<DataPoint>) {
                    for (dataPoint in dataPoints) {
                        val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE)
                        val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS)
                        val ibiList = dataPoint.getValue(ValueKey.HeartRateSet.IBI_LIST) as? List<Int>
                        val ibiStatusList = dataPoint.getValue(ValueKey.HeartRateSet.IBI_STATUS_LIST) as? List<Int>
                        
                        // Filter valid IBI values
                        val validIbi = mutableListOf<Int>()
                        if (ibiList != null && ibiStatusList != null) {
                            ibiList.forEachIndexed { index, ibi ->
                                if (ibiStatusList.getOrNull(index) == 0) {
                                    validIbi.add(ibi)
                                }
                            }
                        }
                        
                        // Calculate HRV
                        val hrv = calculateHRV(validIbi)
                        
                        val data = mapOf(
                            "hr" to hrValue,
                            "hrStatus" to hrStatus,
                            "ibi" to validIbi,
                            "hrv" to hrv,
                            "timestamp" to System.currentTimeMillis()
                        )
                        
                        eventSink.success(data)
                        Log.d(TAG, "📊 HR: $hrValue, IBI: ${validIbi.size} values, HRV: $hrv")
                    }
                }

                override fun onFlushCompleted() {
                    Log.i(TAG, "Flush completed")
                }

                override fun onError(error: HealthTracker.TrackerError?) {
                    Log.e(TAG, "Tracker error: ${error?.name}")
                    eventSink.error(
                        "TRACKER_ERROR",
                        error?.name ?: "Unknown tracker error",
                        null
                    )
                }
            }
            
            heartRateTracker?.setEventListener(trackerEventListener)
            Log.i(TAG, "✅ Heart rate tracking started")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start tracking: ${e.message}")
            eventSink.error(
                "START_TRACKING_FAILED",
                e.message ?: "Unknown error",
                null
            )
        }
    }
    
    fun stopHeartRateTracking() {
        heartRateTracker?.unsetEventListener()
        heartRateTracker?.flush()
        heartRateTracker = null
        Log.i(TAG, "⏹️ Heart rate tracking stopped")
    }
    
    // ============ HELPER FUNCTIONS ============
    
    private fun calculateHRV(ibiList: List<Int>): Double {
        if (ibiList.size < 2) return 0.0
        
        val differences = mutableListOf<Double>()
        for (i in 0 until ibiList.size - 1) {
            val diff = (ibiList[i + 1] - ibiList[i]).toDouble()
            differences.add(diff * diff)
        }
        
        return if (differences.isNotEmpty()) {
            kotlin.math.sqrt(differences.average())
        } else {
            0.0
        }
    }
    
    fun disconnect() {
        stopHeartRateTracking()
        healthTrackingService?.disconnectService()
        healthTrackingService = null
        isConnecting = false
        Log.i(TAG, "🔌 Disconnected from Health Tracking Service")
    }
}package com.example.pulsify

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pulsify/health_tracking"
    private val EVENT_CHANNEL = "com.example.pulsify/heart_rate_stream"
    
    private var healthTrackingManager: HealthTrackingManager? = null
    private var heartRateStreamHandler: HeartRateStreamHandler? = null
    
    // Permission request code
    private val PERMISSION_REQUEST_CODE = 100
    private var pendingResult: MethodChannel.Result? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Method Channel for connection & control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val hasPermission = checkHealthPermission()
                    result.success(hasPermission)
                }
                
                "requestPermission" -> {
                    pendingResult = result
                    requestHealthPermission()
                }
                
                "connect" -> {
                    // Check permission first
                    if (!checkHealthPermission()) {
                        result.error(
                            "PERMISSION_DENIED",
                            "Health sensor permission not granted. Call requestPermission() first.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    
                    healthTrackingManager = HealthTrackingManager(this, result)
                    healthTrackingManager?.connectToHealthTrackingService()
                }
                
                "disconnect" -> {
                    healthTrackingManager?.disconnect()
                    healthTrackingManager = null
                    result.success(true)
                }
                
                "getRequiredPermission" -> {
                    val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
                        HealthTrackingManager.HEALTH_READ_HR_PERMISSION
                    } else {
                        HealthTrackingManager.BODY_SENSORS_PERMISSION
                    }
                    result.success(permission)
                }
                
                else -> result.notImplemented()
            }
        }
        
        // Event Channel for heart rate streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    events?.let { sink ->
                        if (!checkHealthPermission()) {
                            sink.error(
                                "PERMISSION_DENIED",
                                "Health sensor permission not granted",
                                null
                            )
                            return
                        }
                        
                        heartRateStreamHandler = HeartRateStreamHandler(healthTrackingManager, sink)
                        healthTrackingManager?.startHeartRateTracking(sink)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    healthTrackingManager?.stopHeartRateTracking()
                    heartRateStreamHandler = null
                }
            }
        )
    }
    
    // ============ PERMISSION HANDLING ============
    
    private fun checkHealthPermission(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            HealthTrackingManager.HEALTH_READ_HR_PERMISSION
        } else {
            HealthTrackingManager.BODY_SENSORS_PERMISSION
        }
        
        return ContextCompat.checkSelfPermission(
            this,
            permission
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestHealthPermission() {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            HealthTrackingManager.HEALTH_READ_HR_PERMISSION
        } else {
            HealthTrackingManager.BODY_SENSORS_PERMISSION
        }
        
        ActivityCompat.requestPermissions(
            this,
            arrayOf(permission),
            PERMISSION_REQUEST_CODE
        )
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        healthTrackingManager?.disconnect()
    }
}

// Helper class for streaming
class HeartRateStreamHandler(
    private val manager: HealthTrackingManager?,
    private val eventSink: EventChannel.EventSink
)import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class WatchBridgeService {
  static const MethodChannel _channel = MethodChannel('com.example.pulsify/health_tracking');
  static const EventChannel _eventChannel = EventChannel('com.example.pulsify/heart_rate_stream');
  
  final Logger _logger = Logger();
  
  bool _isConnected = false;
  StreamSubscription? _heartRateSubscription;
  
  // ============ PERMISSION HANDLING ============
  
  /// Check if health sensor permission is granted
  Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkPermission');
      _logger.i('📋 Permission check: ${hasPermission ? "GRANTED" : "DENIED"}');
      return hasPermission;
    } catch (e) {
      _logger.e('❌ Error checking permission: $e');
      return false;
    }
  }
  
  /// Request health sensor permission from user
  Future<bool> requestPermission() async {
    try {
      _logger.i('🔐 Requesting health sensor permission');
      final bool granted = await _channel.invokeMethod('requestPermission');
      
      if (granted) {
        _logger.i('✅ Permission granted');
      } else {
        _logger.w('❌ Permission denied');
      }
      
      return granted;
    } catch (e) {
      _logger.e('❌ Error requesting permission: $e');
      return false;
    }
  }
  
  /// Get the required permission string
  Future<String> getRequiredPermission() async {
    try {
      final String permission = await _channel.invokeMethod('getRequiredPermission');
      return permission;
    } catch (e) {
      _logger.e('❌ Error getting required permission: $e');
      return 'android.permission.BODY_SENSORS';
    }
  }
  
  // ============ CONNECTION HANDLING ============
  
  /// Connect to Samsung Health Tracking Service
  /// IMPORTANT: Checks permission first, requests if needed
  Future<Map<String, dynamic>> connectToWatch() async {
    try {
      _logger.i('💡 Attempting to connect to watch');
      
      // STEP 1: Check permission first
      bool hasPermission = await checkPermission();
      
      // STEP 2: Request if not granted
      if (!hasPermission) {
        _logger.w('⚠️ Permission not granted, requesting...');
        hasPermission = await requestPermission();
        
        if (!hasPermission) {
          throw Exception('User denied health sensor permission');
        }
      }
      
      // STEP 3: Now connect (permission is guaranteed)
      _logger.i('✅ Permission granted, connecting to Health Tracking Service');
      
      final result = await _channel.invokeMethod('connect').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out after 10 seconds');
        },
      );
      
      _isConnected = true;
      _logger.i('✅ Successfully connected to watch');
      
      return {
        'connected': result['connected'] ?? false,
        'message': result['message'] ?? 'Connected',
        'capabilities': result['capabilities'] ?? [],
      };
      
    } on TimeoutException catch (e) {
      _logger.e('⏱️ Connection timeout: $e');
      _isConnected = false;
      rethrow;
    } on PlatformException catch (e) {
      _logger.e('❌ Platform exception: ${e.message}');
      _isConnected = false;
      
      if (e.code == 'PERMISSION_DENIED') {
        throw Exception('Health sensor permission denied. Please grant permission in system settings.');
      }
      
      rethrow;
    } catch (e) {
      _logger.e('❌ Connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }
  
  /// Disconnect from Health Tracking Service
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _logger.i('🔌 Disconnected from watch');
    } catch (e) {
      _logger.e('❌ Error disconnecting: $e');
    }
  }
  
  // ============ HEART RATE STREAMING ============
  
  /// Start streaming heart rate data
  Stream<Map<String, dynamic>> startHeartRateStream() {
    if (!_isConnected) {
      throw Exception('Not connected to watch. Call connectToWatch() first.');
    }
    
    _logger.i('📊 Starting heart rate stream');
    
    return _eventChannel.receiveBroadcastStream().map((data) {
      if (data is Map) {
        return {
          'hr': data['hr'] ?? 0,
          'hrStatus': data['hrStatus'] ?? -1,
          'ibi': List<int>.from(data['ibi'] ?? []),
          'hrv': data['hrv'] ?? 0.0,
          'timestamp': data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        };
      }
      return <String, dynamic>{};
    }).handleError((error) {
      _logger.e('❌ Heart rate stream error: $error');
      throw error;
    });
  }
  
  /// Stop heart rate streaming
  Future<void> stopHeartRateStream() async {
    await _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    _logger.i('⏹️ Stopped heart rate stream');
  }
  
  // ============ UTILITY ============
  
  bool get isConnected => _isConnected;
  
  /// Full initialization flow with permission handling
  Future<bool> initialize() async {
    try {
      _logger.i('🚀 Initializing Watch Bridge Service');
      
      // Check permission
      bool hasPermission = await checkPermission();
      
      if (!hasPermission) {
        _logger.w('⚠️ Permission not granted yet');
        return false;
      }
      
      // Connect
      final result = await connectToWatch();
      
      _logger.i('✅ Watch Bridge Service initialized successfully');
      return result['connected'] == true;
      
    } catch (e) {
      _logger.e('❌ Initialization failed: $e');
      return false;
    }
  }
  
  void dispose() {
    stopHeartRateStream();
    disconnect();
  }
}import 'package:flutter/material.dart';
import 'package:your_app/services/watch_bridge.dart';

class WearHeartRateScreen extends StatefulWidget {
  const WearHeartRateScreen({Key? key}) : super(key: key);

  @override
  State<WearHeartRateScreen> createState() => _WearHeartRateScreenState();
}

class _WearHeartRateScreenState extends State<WearHeartRateScreen> {
  final WatchBridgeService _watchBridge = WatchBridgeService();
  
  bool _hasPermission = false;
  bool _isConnected = false;
  bool _isMonitoring = false;
  bool _isLoading = false;
  String _statusMessage = 'Initializing...';
  
  int _currentHR = 0;
  double _currentHRV = 0.0;
  List<int> _currentIBI = [];
  
  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }
  
  // ============ PERMISSION FLOW ============
  
  Future<void> _checkPermissionStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permissions...';
    });
    
    try {
      final hasPermission = await _watchBridge.checkPermission();
      
      if (!mounted) return;
      
      setState(() {
        _hasPermission = hasPermission;
        _isLoading = false;
        _statusMessage = hasPermission 
            ? 'Permission granted' 
            : 'Permission required';
      });
      
      // Auto-connect if permission granted
      if (hasPermission) {
        await _connectToWatch();
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error checking permission: $e';
      });
    }
  }
  
  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting permission...';
    });
    
    try {
      final granted = await _watchBridge.requestPermission();
      
      if (!mounted) return;
      
      setState(() {
        _hasPermission = granted;
        _isLoading = false;
        _statusMessage = granted 
            ? 'Permission granted!' 
            : 'Permission denied';
      });
      
      // Auto-connect if granted
      if (granted) {
        await _connectToWatch();
      } else {
        _showPermissionDeniedDialog();
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error requesting permission: $e';
      });
    }
  }
  
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Health sensor permission is required to monitor heart rate. '
          'Please grant permission in system settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermission();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  // ============ CONNECTION FLOW ============
  
  Future<void> _connectToWatch() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to watch...';
    });
    
    try {
      final result = await _watchBridge.connectToWatch();
      
      if (!mounted) return;
      
      setState(() {
        _isConnected = result['connected'] == true;
        _isLoading = false;
        _statusMessage = result['message'] ?? 'Connected';
      });
      
      if (_isConnected) {
        _showSnackBar('✅ Connected to watch', Colors.green);
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Connection failed: $e';
      });
      
      _showSnackBar('❌ Connection failed', Colors.red);
    }
  }
  
  // ============ HEART RATE MONITORING ============
  
  Future<void> _startMonitoring() async {
    if (!_hasPermission) {
      _showSnackBar('Permission not granted', Colors.orange);
      await _requestPermission();
      return;
    }
    
    if (!_isConnected) {
      _showSnackBar('Not connected to watch', Colors.orange);
      await _connectToWatch();
      return;
    }
    
    setState(() {
      _isMonitoring = true;
      _statusMessage = 'Monitoring heart rate...';
    });
    
    try {
      _watchBridge.startHeartRateStream().listen(
        (data) {
          if (!mounted) return;
          
          setState(() {
            _currentHR = data['hr'] as int;
            _currentHRV = data['hrv'] as double;
            _currentIBI = data['ibi'] as List<int>;
            _statusMessage = 'Receiving data...';
          });
        },
        onError: (error) {
          if (!mounted) return;
          
          setState(() {
            _isMonitoring = false;
            _statusMessage = 'Stream error: $error';
          });
          
          _showSnackBar('❌ Monitoring error', Colors.red);
        },
        onDone: () {
          if (!mounted) return;
          
          setState(() {
            _isMonitoring = false;
            _statusMessage = 'Monitoring stopped';
          });
        },
      );
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isMonitoring = false;
        _statusMessage = 'Failed to start monitoring: $e';
      });
    }
  }
  
  Future<void> _stopMonitoring() async {
    await _watchBridge.stopHeartRateStream();
    
    if (!mounted) return;
    
    setState(() {
      _isMonitoring = false;
      _statusMessage = 'Monitoring stopped';
    });
  }
  
  // ============ UI HELPERS ============
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // ============ BUILD UI ============
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              _buildStatusCard(),
              
              const SizedBox(height: 16),
              
              // Permission Section
              if (!_hasPermission) _buildPermissionSection(),
              
              // Heart Rate Data Section
              if (_hasPermission && _isConnected) ...[
                _buildHeartRateCard(),
                const SizedBox(height: 16),
                _buildHRVCard(),
                const SizedBox(height: 16),
                _buildIBICard(),
              ],
              
              const SizedBox(height: 24),
              
              // Control Buttons
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error_outline,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPermissionSection() {
    return Card(
      color: Colors.orange[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Health sensor permission is needed to monitor your heart rate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _requestPermission,
              icon: const Icon(Icons.lock_open),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeartRateCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '❤️ Heart Rate',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _currentHR > 0 ? '$_currentHR BPM' : '--',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHRVCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '📊 HRV (RMSSD)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _currentHRV > 0 ? '${_currentHRV.toStringAsFixed(1)} ms' : '--',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIBICard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💓 IBI Values',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _currentIBI.isEmpty 
                  ? 'No IBI data' 
                  : '${_currentIBI.length} values (latest: ${_currentIBI.last}ms)',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButtons() {
    return Column(
      children: [
        if (_hasPermission && _isConnected)
          ElevatedButton.icon(
            onPressed: _isLoading 
                ? null 
                : (_isMonitoring ? _stopMonitoring : _startMonitoring),
            icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
            label: Text(_isMonitoring ? 'STOP MONITORING' : 'START MONITORING'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMonitoring ? Colors.red : Colors.green,
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        
        if (!_hasPermission)
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _requestPermission,
            icon: const Icon(Icons.lock_open),
            label: const Text('REQUEST PERMISSION'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        
        if (_hasPermission && !_isConnected)
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _connectToWatch,
            icon: const Icon(Icons.watch),
            label: const Text('CONNECT TO WATCH'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    _watchBridge.dispose();
    super.dispose();
  }
}package com.example.pulsify

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.samsung.android.service.health.tracking.ConnectionListener
import com.samsung.android.service.health.tracking.HealthTracker
import com.samsung.android.service.health.tracking.HealthTrackerException
import com.samsung.android.service.health.tracking.HealthTrackingService
import com.samsung.android.service.health.tracking.data.DataPoint
import com.samsung.android.service.health.tracking.data.HealthTrackerType
import com.samsung.android.service.health.tracking.data.ValueKey
import io.flutter.plugin.common.EventChannel as FlutterEventChannel
import io.flutter.plugin.common.MethodChannel

private const val TAG = "HealthTrackingManager"

class HealthTrackingManager(
    private val context: Context,
    private val result: MethodChannel.Result
) {
    
    private var healthTrackingService: HealthTrackingService? = null
    private var heartRateTracker: HealthTracker? = null
    private var isConnecting = false
    
    companion object {
        // Required permission
        const val BODY_SENSORS_PERMISSION = "android.permission.BODY_SENSORS"
        const val HEALTH_READ_HR_PERMISSION = "android.permission.health.READ_HEART_RATE"
    }
    
    // ============ PERMISSION HANDLING ============
    
    fun checkPermission(): Boolean {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            HEALTH_READ_HR_PERMISSION
        } else {
            BODY_SENSORS_PERMISSION
        }
        
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            permission
        ) == PackageManager.PERMISSION_GRANTED
        
        Log.i(TAG, "📋 Permission check: $permission = ${if (hasPermission) "GRANTED" else "DENIED"}")
        return hasPermission
    }
    
    fun getRequiredPermission(): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            HEALTH_READ_HR_PERMISSION
        } else {
            BODY_SENSORS_PERMISSION
        }
    }
    
    // ============ CONNECTION HANDLING ============
    
    fun connectToHealthTrackingService() {
        if (isConnecting) {
            Log.w(TAG, "⚠️ Already attempting to connect, ignoring duplicate request")
            return
        }
        
        // CRITICAL: Check permission FIRST
        if (!checkPermission()) {
            Log.e(TAG, "❌ BODY_SENSORS permission not granted!")
            result.error(
                "PERMISSION_DENIED",
                "Health sensor permission not granted. Request permission first.",
                null
            )
            return
        }
        
        isConnecting = true
        Log.i(TAG, "🔄 Attempting to connect to Health Tracking Service")
        
        val connectionListener = object : ConnectionListener {
            override fun onConnectionSuccess() {
                Log.i(TAG, "✅ Connected to Health Tracking Service")
                isConnecting = false
                healthTrackingService = HealthTrackingService(connectionListener, context)
                
                // Verify capabilities
                val capabilities = healthTrackingService?.trackingCapability?.supportHealthTrackerTypes
                Log.i(TAG, "📊 Available trackers: ${capabilities?.joinToString()}")
                
                result.success(mapOf(
                    "connected" to true,
                    "message" to "Connected to Health Tracking Service",
                    "capabilities" to capabilities?.map { it.name }
                ))
            }

            override fun onConnectionEnded() {
                Log.w(TAG, "⚠️ Connection ended")
                isConnecting = false
                result.error(
                    "CONNECTION_ENDED",
                    "Health Tracking Service connection ended",
                    null
                )
            }

            override fun onConnectionFailed(exception: HealthTrackerException?) {
                Log.e(TAG, "❌ Connection failed: ${exception?.message}")
                isConnecting = false
                
                val errorMessage = when (exception?.errorCode) {
                    HealthTrackerException.OLD_PLATFORM_VERSION -> 
                        "Device platform too old"
                    HealthTrackerException.PACKAGE_NAME_MISMATCH -> 
                        "Package name mismatch"
                    HealthTrackerException.SDK_POLICY_ERROR -> 
                        "SDK policy error - check Samsung Health permissions"
                    HealthTrackerException.SDK_NOT_SUPPORTED_ERROR -> 
                        "SDK not supported on this device"
                    else -> 
                        exception?.message ?: "Unknown error"
                }
                
                result.error(
                    "CONNECTION_FAILED",
                    errorMessage,
                    mapOf("errorCode" to exception?.errorCode)
                )
            }
        }

        try {
            Log.i(TAG, "⏳ Waiting for connection callback...")
            healthTrackingService = HealthTrackingService(connectionListener, context)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Exception during connection: ${e.message}")
            isConnecting = false
            result.error(
                "CONNECTION_EXCEPTION",
                e.message ?: "Unknown exception",
                null
            )
        }
    }
    
    // ============ HEART RATE TRACKING ============
    
    fun startHeartRateTracking(eventSink: FlutterEventChannel.EventSink) {
        if (!checkPermission()) {
            eventSink.error(
                "PERMISSION_DENIED",
                "Health sensor permission not granted",
                null
            )
            return
        }
        
        if (healthTrackingService == null) {
            eventSink.error(
                "NOT_CONNECTED",
                "Not connected to Health Tracking Service",
                null
            )
            return
        }
        
        try {
            heartRateTracker = healthTrackingService?.getHealthTracker(
                HealthTrackerType.HEART_RATE_CONTINUOUS
            )
            
            val trackerEventListener = object : HealthTracker.TrackerEventListener {
                override fun onDataReceived(dataPoints: MutableList<DataPoint>) {
                    for (dataPoint in dataPoints) {
                        val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE)
                        val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS)
                        val ibiList = dataPoint.getValue(ValueKey.HeartRateSet.IBI_LIST) as? List<Int>
                        val ibiStatusList = dataPoint.getValue(ValueKey.HeartRateSet.IBI_STATUS_LIST) as? List<Int>
                        
                        // Filter valid IBI values
                        val validIbi = mutableListOf<Int>()
                        if (ibiList != null && ibiStatusList != null) {
                            ibiList.forEachIndexed { index, ibi ->
                                if (ibiStatusList.getOrNull(index) == 0) {
                                    validIbi.add(ibi)
                                }
                            }
                        }
                        
                        // Calculate HRV
                        val hrv = calculateHRV(validIbi)
                        
                        val data = mapOf(
                            "hr" to hrValue,
                            "hrStatus" to hrStatus,
                            "ibi" to validIbi,
                            "hrv" to hrv,
                            "timestamp" to System.currentTimeMillis()
                        )
                        
                        eventSink.success(data)
                        Log.d(TAG, "📊 HR: $hrValue, IBI: ${validIbi.size} values, HRV: $hrv")
                    }
                }

                override fun onFlushCompleted() {
                    Log.i(TAG, "Flush completed")
                }

                override fun onError(error: HealthTracker.TrackerError?) {
                    Log.e(TAG, "Tracker error: ${error?.name}")
                    eventSink.error(
                        "TRACKER_ERROR",
                        error?.name ?: "Unknown tracker error",
                        null
                    )
                }
            }
            
            heartRateTracker?.setEventListener(trackerEventListener)
            Log.i(TAG, "✅ Heart rate tracking started")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start tracking: ${e.message}")
            eventSink.error(
                "START_TRACKING_FAILED",
                e.message ?: "Unknown error",
                null
            )
        }
    }
    
    fun stopHeartRateTracking() {
        heartRateTracker?.unsetEventListener()
        heartRateTracker?.flush()
        heartRateTracker = null
        Log.i(TAG, "⏹️ Heart rate tracking stopped")
    }
    
    // ============ HELPER FUNCTIONS ============
    
    private fun calculateHRV(ibiList: List<Int>): Double {
        if (ibiList.size < 2) return 0.0
        
        val differences = mutableListOf<Double>()
        for (i in 0 until ibiList.size - 1) {
            val diff = (ibiList[i + 1] - ibiList[i]).toDouble()
            differences.add(diff * diff)
        }
        
        return if (differences.isNotEmpty()) {
            kotlin.math.sqrt(differences.average())
        } else {
            0.0
        }
    }
    
    fun disconnect() {
        stopHeartRateTracking()
        healthTrackingService?.disconnectService()
        healthTrackingService = null
        isConnecting = false
        Log.i(TAG, "🔌 Disconnected from Health Tracking Service")
    }
}