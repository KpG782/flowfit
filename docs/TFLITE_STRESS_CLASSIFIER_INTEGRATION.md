# TFLite Stress Classifier — Integration Guide

> This document explains how the on-device AI stress classifier works in Pulsify: where the
> sensor data comes from, how it travels from the smartwatch to the model, and how the result
> reaches the user interface. Read this before touching any code in `TrackerPage`,
> `WellnessTrackerPage`, or any sensor bridge.

---

## 1. What This System Does

During a live session the app reads **accelerometer** (movement) and **heart rate** (BPM) data
from a paired Galaxy Watch. Those two signals are combined into a rolling feature window and fed
into a TensorFlow Lite model that runs **entirely on the phone** — no server, no internet call.
The model returns one of four activity/stress labels every time the window fills:

| Label | Meaning |
|---|---|
| `Calm` | Low movement, normal or low heart rate |
| `Stress` | Elevated heart rate, irregular or tense movement patterns |
| `Cardio` | Sustained high movement + elevated HR (intentional exercise) |
| `Strength` | Burst movement, moderate HR (resistance/lifting patterns) |

A confidence percentage accompanies every label. The label and confidence are displayed live on
screen, and a `Stress` result can trigger downstream UI actions such as suggesting calming
walking routes.

---

## 2. The Full Data Journey

```
GALAXY WATCH (Wear OS)
  │
  │  Samsung Health Sensor SDK
  │  HealthTrackingManager.kt
  │    ├── Accelerometer  (x, y, z in m/s²)
  │    └── Heart Rate     (BPM + IBI values)
  │
  │  WatchToPhoneSyncManager.kt
  │  Wearable MessageClient  →  path: "/heart_rate"
  │
  ▼
ANDROID PHONE
  │
  │  PhoneDataListenerService.kt   (WearableListenerService)
  │  MainActivity.kt (Phone)       (EventChannel → Dart)
  │
  │  PhoneDataService.dart         (decodes JSON → HeartRateData)
  │
  ▼
FLUTTER (Dart)
  │
  │  SensorDataPipeline
  │    ├── AccelerometerStream  (watch bridge OR phone IMU OR simulation)
  │    └── HeartRateStream      (watch bridge OR camera OR simulation)
  │
  │  SlidingWindowBuffer (320 samples)
  │    → filled sample-by-sample as sensor events arrive
  │    → triggers inference when full
  │
  ▼
TFLITE MODEL  (assets/model.tflite — runs on-device)
  │
  │  Input tensor:  [1 × 320 × features]
  │  Output tensor: [1 × 4]  (softmax probabilities)
  │
  ▼
UI LABEL
  TrackerPage  /trackertest
  WellnessTrackerPage  /wellness-tracker
    → Calm / Stress / Cardio / Strength  +  confidence %
    → Stress label → "Show Routes" banner → /mission
```

---

## 3. The Two Sensor Streams

### 3A — Accelerometer

The accelerometer reports three axes (x, y, z) up to ~50 Hz from the watch.
What matters for the model is **motion magnitude** — a scalar computed as:

```
magnitude = sqrt(x² + y² + z²)
```

This collapses the three axes into one number that describes "how much the wrist is moving"
regardless of orientation. If you ever change how the magnitude is computed, the model must be
retrained because the training data used the same formula.

Raw axes can also be kept as separate features (see Section 4).

### 3B — Heart Rate

Heart rate arrives as:

- `bpm` — beats per minute (integer, validated on-watch before transmission)
- `ibiValues` — inter-beat intervals in milliseconds (array, one value per beat)

For the classifier, **BPM** is the primary feature. IBI can be used to derive Heart Rate
Variability (HRV), which is a strong stress indicator, but only if enough IBI values arrive
within the window — treat it as an optional enrichment.

### 3C — Source Selector

`TrackerPage` exposes a source selector so the same classifier code runs in three modes:

| Mode | Accelerometer source | Heart rate source |
|---|---|---|
| `Watch` | Samsung Health SDK via `WatchBridgeService` | Samsung Health SDK via `WatchBridgeService` |
| `Phone` | Android/iOS IMU via `sensors_plus` package | Camera photoplethysmography (PPG) |
| `Simulation` | Synthetic sine/noise generator | Simulation slider (manual BPM) |

Simulation mode lets you test and demo the UI without any hardware connected.

---

## 4. The Sliding Window Buffer

The model was trained on **windows of 320 samples**. This is a fixed contract — do not change
the window size without retraining the model.

### Why 320 samples?

At a sensor delivery rate of ~20 Hz (the practical average after Bluetooth jitter):

```
320 samples ÷ 20 Hz = 16 seconds per inference
```

Sixteen seconds is long enough to distinguish a sustained stress pattern from a momentary spike,
and short enough to give near-real-time feedback.

### How the buffer works

```dart
// Conceptual — simplified
const int windowSize = 320;
final List<SampleRow> _window = [];

void onNewSample(double accelMagnitude, int bpm) {
  _window.add(SampleRow(accel: accelMagnitude, bpm: bpm));

  if (_window.length > windowSize) {
    _window.removeAt(0);          // slide: drop oldest sample
  }

  if (_window.length == windowSize) {
    _runInference(_window);       // window is full — infer
  }
}
```

The window **slides**: each new sample pushes the oldest one out, so inference runs on a
continuously updated 16-second view rather than waiting for non-overlapping blocks. This gives
smoother label transitions in the UI.

---

## 5. Feature Layout Inside the Window

Each row in the window is one timestep. The exact feature columns the model expects depend on
how it was trained. Document any change here if the model is retrained.

**Current feature order (per timestep):**

| Column index | Feature | Unit |
|---|---|---|
| 0 | Accelerometer magnitude | m/s² |
| 1 | Heart rate BPM | beats/min (normalised 0–1) |

If axes are included separately:

| Column index | Feature | Unit |
|---|---|---|
| 0 | Accel X | m/s² |
| 1 | Accel Y | m/s² |
| 2 | Accel Z | m/s² |
| 3 | Accel magnitude | m/s² |
| 4 | Heart rate BPM | beats/min (normalised 0–1) |

> **Rule:** normalise BPM to [0, 1] using the same range used during training (e.g. 40–200 BPM).
> Raw BPM integers will produce garbage predictions if the training data was normalised.

---

## 6. Running TFLite Inference

The model file lives in `assets/model.tflite` and is loaded once when the page initialises.

```dart
// Pseudocode — mirrors what TrackerPage does
final interpreter = await Interpreter.fromAsset('model.tflite');

void _runInference(List<SampleRow> window) {
  // Shape: [1, 320, numFeatures]
  final input = [window.map((s) => [s.accel, s.bpmNorm]).toList()];

  // Shape: [1, 4]  — softmax output for [Calm, Stress, Cardio, Strength]
  final output = List.filled(4, 0.0).reshape([1, 4]);

  interpreter.run(input, output);

  final probs = output[0] as List<double>;
  final labelIndex = probs.indexOf(probs.reduce(max));
  final confidence = (probs[labelIndex] * 100).round();

  _updateUI(_labels[labelIndex], confidence);
}

const _labels = ['Calm', 'Stress', 'Cardio', 'Strength'];
```

The Flutter package for inference is `tflite_flutter`. The `Interpreter` object is expensive to
create — create it once on page init and dispose it in `dispose()`.

---

## 7. How It Fits Into the Existing Architecture

```
SplashScreen
    └── /dashboard
            ├── Tab 0 — HomeScreen
            │       └── "AI Activity Tracker" card
            │               └──▶ /trackertest  ← TrackerPage
            │                       (standalone TFLite live view)
            │
            ├── Tab 1 — HealthScreen
            │       └── live BPM display (watch bridge, no inference)
            │
            └── /wellness-tracker  ← WellnessTrackerPage
                    └── live BPM + accel + TFLite inline
                            └── Stress detected
                                    └── "Show Routes" ──▶ /mission
```

There are **two places** that run the classifier:

| Screen | Route | Used during |
|---|---|---|
| `TrackerPage` | `/trackertest` | Standalone AI tracker card, shortcut from `ActiveRunningScreen` |
| `WellnessTrackerPage` | `/wellness-tracker` | Wellness flow — full-screen ambient monitoring |

Both screens share the same underlying sensor bridge and TFLite inference logic. If you extract
the pipeline into a dedicated service/provider, both screens can consume it without duplicating
code.

---

## 8. Sensor Data Path in Code (File Map)

| Layer | File | Responsibility |
|---|---|---|
| Watch native | `watch/android/.../HealthTrackingManager.kt` | Samsung Health SDK — collects HR + accel from sensors |
| Watch native | `watch/android/.../WatchToPhoneSyncManager.kt` | Sends JSON over Wearable MessageClient |
| Phone native | `android/.../PhoneDataListenerService.kt` | Receives `/heart_rate` messages, fires EventChannel |
| Phone native | `android/.../MainActivity.kt` (phone) | Registers EventChannel handler |
| Dart bridge | `lib/.../watch_bridge_service.dart` | `WatchBridgeService` — exposes `heartRateStream` |
| Dart bridge | `lib/.../phone_data_service.dart` | Decodes JSON → `HeartRateData` |
| Dart model | `lib/.../unified_sensor_manager.dart` | `UnifiedSensorManager` — merges accel + HR streams |
| Dart UI | `lib/features/tracker/tracker_page.dart` | `TrackerPage` — sliding window + TFLite + UI |
| Dart UI | `lib/features/wellness/wellness_tracker_page.dart` | `WellnessTrackerPage` — inline classifier |
| Asset | `assets/model.tflite` | Compiled TFLite flatbuffer (trained offline) |

---

## 9. Timing and Synchronisation

Accelerometer and heart rate arrive on **different schedules**:

- Accelerometer: ~20–50 Hz (high frequency, regular)
- Heart rate: ~1 Hz (once per second, sometimes slower)

The window is indexed by **accelerometer samples**, not by time. Each accelerometer sample is
paired with the **most recent BPM** available at that moment:

```
Accel sample arrives  →  look up latest BPM from heartRateStream
                      →  write [accelMagnitude, latestBpm] into window
```

This means one BPM value is reused across multiple accelerometer samples (typically 20–50
times per second). That is intentional and consistent with how the model was trained.

If no BPM reading has arrived yet, hold the window — do not fill it with zeroes, as that would
corrupt the feature distribution.

---

## 10. Downstream Actions on Stress Detection

When the classifier outputs `Stress`:

```
TrackerPage / WellnessTrackerPage
    └── label == 'Stress'
            └── show stress banner / alert widget
                    └── user taps "Show Routes"
                            └──▶ /mission  (MapsPageWrapper)
                                    └── OpenRouteService API
                                            └── nearby calming walking routes on GPS map
```

The stress banner only appears when the model is confident. A reasonable threshold is
**confidence >= 65%** sustained across **3 consecutive windows** (≈ 48 seconds) to avoid
triggering on a single anomalous window.

---

## 11. Key Things That Break the Model

These are the most common mistakes. Check this list first when predictions look wrong.

1. **Window size mismatch** — model expects exactly 320 timesteps. Sending 319 or 321 causes
   a shape error or silent misclassification.

2. **BPM not normalised** — if training used BPM / 200, inference must too. Raw BPM of 80
   will look like 0.4 to a normalised model but 80.0 to a raw model.

3. **Feature column order changed** — swapping accel and BPM columns produces nonsense output
   without throwing any error.

4. **Interpreter not disposed** — creating a new `Interpreter` on every inference call causes
   memory growth and eventually crashes. Create once, reuse, dispose on page exit.

5. **Filling the window before the first BPM arrives** — using 0 BPM as a placeholder skews
   the feature distribution toward "Calm" because the model was trained on real resting BPM
   (≈ 60–80), not zero.

6. **Sampling rate too slow** — if the watch connection drops and accelerometer updates fall
   below ~5 Hz, the window takes over a minute to fill and inference latency becomes noticeable.
   Show a "weak signal" indicator rather than stale results.
