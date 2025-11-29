import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import '../../services/phone_data_listener.dart';
import '../../models/heart_rate_data.dart';

class RandomWorkoutScreen extends StatefulWidget {
  const RandomWorkoutScreen({super.key});

  @override
  State<RandomWorkoutScreen> createState() => _RandomWorkoutScreenState();
}

class _RandomWorkoutScreenState extends State<RandomWorkoutScreen> {
  ObjectDetector? _objectDetector;
  StreamSubscription<HeartRateData>? _heartRateSubscription;
  int _heartRate = 0;
  int _squatCount = 0;
  bool _isSquatting = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initObjectDetector();
    _initHeartRateListener();
  }

  Future<void> _initObjectDetector() async {
    // In a real implementation, we would load a specific model for workout detection.
    // Since we don't have a vision model in assets, we will initialize the detector
    // but it won't detect anything without a valid model path.
    // This is a placeholder for the "Random Workout" feature.
    /*
    final modelPath = await _copyAssetToLocal('assets/model/yolo_model.tflite');
    _objectDetector = ObjectDetector(modelPath: modelPath);
    _objectDetector?.loadModel();
    */
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _initHeartRateListener() {
    final phoneDataListener = context.read<PhoneDataListener>();
    _heartRateSubscription = phoneDataListener.heartRateStream.listen((data) {
      setState(() {
        _heartRate = data.bpm ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    // _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera View
          if (_isCameraInitialized)
            UltralyticsYoloCamera(
              predictor: _objectDetector,
              onCameraCreated: (controller) {
                // Camera controller created
              },
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Initializing Camera...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_heartRate BPM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Flowy Character & Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/flowy.svg',
                        height: 80,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Let\'s do some Squats!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Count: $_squatCount',
                              style: const TextStyle(
                                color: Colors.yellow,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Simulate Button (For testing without actual detection)
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _squatCount++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
