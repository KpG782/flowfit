# AI Stress / Calm Classification — Mobile Extraction Guide

How to lift the TensorFlow Lite heart-rate–based stress and calm classifier out of Pulsify and drop it into a new Flutter project (Android + Kotlin native bridge).

---

## What This Module Does

The module streams **live [accX, accY, accZ, bpm]** sensor data from either a Samsung Galaxy Watch (via the Kotlin native bridge) or the phone's own accelerometer, fills a **320-sample sliding window**, and runs a **TFLite model** on every full window.

The model returns three probabilities:

| Index | Label | Meaning |
|---|---|---|
| 0 | **Stress** | Elevated HR + irregular motion pattern |
| 1 | **Cardio** | Steady elevated HR + rhythmic motion (running/cycling) |
| 2 | **Strength** | High-amplitude motion bursts (weights, HIIT) |

A pre-inference **Calm gate** short-circuits the model when current BPM < 85 and returns the label **"Calm"** directly — no inference cost.

---

## Files to Extract

### Files you need to **move**

| Source path (relative to `lib/`) | Destination (your new project) |
|---|---|
| `features/activity_classifier/platform/tflite_activity_classifier.dart` | Same path |
| `features/activity_classifier/platform/heart_bpm_adapter.dart` | Same path |
| `features/activity_classifier/domain/activity.dart` | Same path |
| `features/activity_classifier/domain/classify_activity_usecase.dart` | Same path |
| `features/activity_classifier/data/tflite_activity_repository.dart` | Same path |
| `features/activity_classifier/data/activity_dto.dart` | Same path |
| `features/activity_classifier/presentation/providers.dart` | Same path |
| `features/activity_classifier/presentation/tracker_page.dart` | Same path (entry-point UI) |
| `widgets/wellness/stress_alert_banner.dart` | Same path |
| `services/calming_route_service.dart` | Same path (optional — stress response) |

### Model asset file (binary — **must copy**)

| Source | Destination |
|---|---|
| `assets/model/activity_tracker.tflite` | `assets/model/activity_tracker.tflite` |
| `android/app/src/main/assets/activity_tracker.tflite` | `android/app/src/main/assets/activity_tracker.tflite` |

> Both copies are required: Flutter loads from `assets/`, Kotlin can optionally load from the Android `assets/` folder for native-side inference.

### Supporting models used by `tracker_page.dart`

These come from the smartwatch extraction (see `SMARTWATCH_EXTRACTION_GUIDE.md`):

| File | Why needed |
|---|---|
| `models/sensor_batch.dart` | `SensorBatch` — 32-sample packet from watch |
| `models/heart_rate_data.dart` | `HeartRateData` DTO |
| `models/sensor_status.dart` | `SensorStatus` enum |
| `services/watch_bridge.dart` | MethodChannel to Kotlin bridge |
| `services/phone_data_listener.dart` | Receives `SensorBatch` events from the watch |

If you are **not** integrating the Galaxy Watch, you can skip these and use the phone-accelerometer or simulation source only (see [Sensor Sources](#sensor-sources) below).

### Tests to copy (optional but recommended)

```
test/features/activity_classifier/
  domain/classify_activity_usecase_test.dart
  data/tflite_activity_repository_test.dart
  platform/tflite_activity_classifier_test.dart
  platform/heart_bpm_adapter_test.dart
```

---

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│  Presentation                                              │
│  TrackerPage  →  ActivityClassifierViewModel               │
└──────────────────────┬─────────────────────────────────────┘
                       │ classify(buffer)
┌──────────────────────▼─────────────────────────────────────┐
│  Domain                                                    │
│  ClassifyActivityUseCase                                   │
│    ├── Calm gate: BPM < 85 → return "Calm" immediately     │
│    └── ActivityClassifierRepository (interface)            │
└──────────────────────┬─────────────────────────────────────┘
                       │ classifyActivity(buffer)
┌──────────────────────▼─────────────────────────────────────┐
│  Data                                                      │
│  TFLiteActivityRepository → ActivityDto.fromPrediction()   │
└──────────────────────┬─────────────────────────────────────┘
                       │ predict(buffer)
┌──────────────────────▼─────────────────────────────────────┐
│  Platform                                                  │
│  TFLiteActivityClassifier (tflite_flutter Interpreter)     │
│  Model: assets/model/activity_tracker.tflite               │
│  Input:  [1, 320, 4]  ← 320 × [accX, accY, accZ, bpm]     │
│  Output: [1, 3]       ← [stress%, cardio%, strength%]      │
└────────────────────────────────────────────────────────────┘
```

Data pipeline:

```
Samsung Watch  ──┐
                 ├──▶  SensorBatch (32 samples)  ──▶  sliding buffer (320 samples)
Phone accel    ──┘                                      │
                                                        ▼
Simulated HR  ──────────────────────────────────  TFLite inference
                                                        │
                                                        ▼
                                                  Activity { label, confidence, probabilities }
                                                        │
                                              label == "Stress" ?
                                                   │         │
                                            show banner   show label
```

---

## Step-by-Step Setup

### 1. Create the Flutter project

```bash
flutter create --org com.yourcompany --platforms android stress_classifier
cd stress_classifier
```

### 2. Add dependencies in `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.12.1      # TFLite runtime
  sensors_plus: ^4.0.2         # Phone accelerometer (optional source)
  heart_bpm: ^2.0.0+0          # Phone camera PPG BPM (optional source)
  permission_handler: ^11.3.0  # Runtime permissions
  provider: ^6.1.0             # State management
  logger: ^2.0.2

flutter:
  assets:
    - assets/model/activity_tracker.tflite
```

### 3. Add the TFLite Android delegate dependency

In `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // tflite_flutter requires these
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0") // optional GPU
}
```

And in your root `android/build.gradle.kts` (repositories block):

```kotlin
repositories {
    google()
    mavenCentral()
}
```

### 4. Copy files

Copy every file listed in [Files to Extract](#files-to-extract) into the equivalent paths under your new project.

Rename package imports (PowerShell, run from project root):

```powershell
Get-ChildItem -Recurse -Filter *.dart lib/ |
  ForEach-Object {
    (Get-Content $_.FullName) -replace "package:pulsify/", "package:stress_classifier/" |
    Set-Content $_.FullName
  }
```

### 5. Place the model asset

```
your_project/
  assets/
    model/
      activity_tracker.tflite      ← copy from Pulsify
  android/
    app/
      src/
        main/
          assets/
            activity_tracker.tflite  ← copy again (for Kotlin-side access)
```

### 6. Register providers in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/activity_classifier/platform/tflite_activity_classifier.dart';
import 'features/activity_classifier/platform/heart_bpm_adapter.dart';
import 'features/activity_classifier/data/tflite_activity_repository.dart';
import 'features/activity_classifier/domain/classify_activity_usecase.dart';
import 'features/activity_classifier/presentation/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load model once at startup
  final classifier = TFLiteActivityClassifier();
  await classifier.loadModel();

  runApp(
    MultiProvider(
      providers: [
        // Platform
        Provider<TFLiteActivityClassifier>.value(value: classifier),

        // Data
        ProxyProvider<TFLiteActivityClassifier, ActivityClassifierRepository>(
          create: (_, c) => TFLiteActivityRepository(c),
          update: (_, c, __) => TFLiteActivityRepository(c),
        ),

        // Domain
        ProxyProvider<ActivityClassifierRepository, ClassifyActivityUseCase>(
          create: (_, r) => ClassifyActivityUseCase(r),
          update: (_, r, __) => ClassifyActivityUseCase(r),
        ),

        // Presentation
        ChangeNotifierProxyProvider<ClassifyActivityUseCase, ActivityClassifierViewModel>(
          create: (_, uc) => ActivityClassifierViewModel(uc),
          update: (_, uc, __) => ActivityClassifierViewModel(uc),
        ),

        // Optional: Heart BPM adapter (connects plugin or watch stream)
        Provider<HeartBpmAdapter>(
          create: (_) => HeartBpmAdapter(),
          dispose: (_, a) => a.dispose(),
        ),
      ],
      child: const MaterialApp(home: TrackerPage()),
    ),
  );
}
```

---

## TFLite Model Reference

### File
`assets/model/activity_tracker.tflite`

### Tensor shapes

| Tensor | Shape | Dtype | Notes |
|---|---|---|---|
| Input | `[1, 320, 4]` | `float32` | Batch × time steps × features |
| Output | `[1, 3]` | `float32` | Batch × class probabilities (softmax) |

### Feature vector (per timestep)

```
index 0 → accX  (m/s²,  from accelerometer)
index 1 → accY  (m/s²)
index 2 → accZ  (m/s²)
index 3 → bpm   (heart rate, float, e.g. 72.0)
```

### Output label mapping

```dart
const labels = ['Stress', 'Cardio', 'Strength'];
// output[0][0] = stress probability
// output[0][1] = cardio probability
// output[0][2] = strength probability
```

### Calm gate (pre-inference shortcut)

In `classify_activity_usecase.dart`:
```dart
if (lastBpm != null && lastBpm < 85.0) {
  return Activity(label: 'Calm', confidence: 0.0, ...);
}
```
The model is never called when BPM is below 85. Labels therefore are: **Calm**, **Stress**, **Cardio**, **Strength**.

---

## Sensor Sources

`TrackerPage` supports three input modes, controlled by `AccelSource` enum:

| Mode | Enum value | How it works |
|---|---|---|
| Phone accelerometer | `AccelSource.Phone` | `sensors_plus` package, adds live events to buffer |
| Simulation | `AccelSource.Simulation` | Synthetic sinusoidal signal at `~32 Hz` |
| Galaxy Watch | `AccelSource.Watch` | `PhoneDataListener.sensorBatchStream` — receives 32-sample `SensorBatch` from Kotlin |

Similarly, BPM has three sources via `BpmSource`:

| Mode | Enum value | How it works |
|---|---|---|
| Simulation | `BpmSource.Simulation` | Slider in UI, default for demos |
| Plugin | `BpmSource.Plugin` | `heart_bpm` camera PPG |
| Watch | `BpmSource.Watch` | Live BPM embedded in each `SensorBatch` from the Galaxy Watch bridge |

---

## Key Classes

### `TFLiteActivityClassifier`

```dart
// Load once at startup
await classifier.loadModel();

// Run inference
final probs = await classifier.predict(buffer); // List<double> length 3
// probs[0] = stress, probs[1] = cardio, probs[2] = strength
```

- Model path: `'assets/model/activity_tracker.tflite'`
- Input validated: must be exactly `320 × 4`
- Throws `StateError` if called before `loadModel()`
- `dispose()` closes the interpreter — call on app shutdown

### `ClassifyActivityUseCase`

```dart
final activity = await useCase.execute(buffer);
// activity.label  → "Calm" | "Stress" | "Cardio" | "Strength"
// activity.confidence → 0.0–1.0
// activity.probabilities → [stress%, cardio%, strength%]
```

### `ActivityClassifierViewModel`

```dart
// Trigger classification
await viewModel.classify(buffer);

// Read result
viewModel.currentActivity?.label   // String
viewModel.currentActivity?.confidence // double
viewModel.isLoading                 // bool
viewModel.hasError                  // bool
```

### `HeartBpmAdapter`

```dart
// Connect phone camera PPG plugin:
adapter.connectExternalStream(HeartBpm.heartBpmStream);

// Or inject any integer stream:
adapter.connectExternalStream(myCustomBpmStream);

// Read current value
adapter.currentBpm  // int?

// Listen for updates
adapter.bpmStream.listen((bpm) { ... });
```

### `StressAlertBanner`

```dart
StressAlertBanner(
  onShowRoutes: () { /* navigate to calming routes */ },
  onDismiss:    () { /* hide banner */ },
  onSnooze:     () { /* remind later */ },
)
```

Slides in from top with a 300ms animation. Trigger it when `activity.label == 'Stress'`.

---

## Integrating Live Heart Rate from the Watch

If you also pull in the smartwatch bridge (see `SMARTWATCH_EXTRACTION_GUIDE.md`), connect the watch BPM stream directly into the classifier:

```dart
// In TrackerPage or your own widget, after watch connects:
final watchBridge = WatchBridgeService();
final heartRateStream = watchBridge.heartRateStream; // Stream<HeartRateData>

// Feed BPM into the adapter
final adapter = context.read<HeartBpmAdapter>();
adapter.connectExternalStream(
  heartRateStream
    .where((d) => d.bpm != null)
    .map((d) => d.bpm!),
);
```

For the full accelerometer + BPM batch path, use the `AccelSource.Watch` mode in `TrackerPage` — it reads `PhoneDataListener.sensorBatchStream` which already delivers pre-packaged `[accX, accY, accZ, bpm]` vectors straight from the Kotlin `WatchSensorService`.

---

## Kotlin Native Bridge (Android)

The Kotlin side does **not** run TFLite — inference is Flutter-side only. Kotlin's role is:

1. Collect accelerometer data at ~50 Hz (`WatchSensorService`)
2. Combine with current BPM into a `SensorBatch` JSON packet
3. Send via `Wearable.getMessageClient` on path `/sensor_data`
4. `PhoneDataListenerService` (WearableListenerService) receives it and fires the `sensorBatchEventSink` which Flutter consumes as `SensorBatch` objects

No additional Kotlin changes are needed for the AI classifier — it is entirely Dart / Flutter.

---

## `AndroidManifest.xml` additions

```xml
<!-- If using phone-side camera BPM (heart_bpm plugin) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- If using accelerometer -->
<uses-feature android:name="android.hardware.sensor.accelerometer" android:required="false" />

<!-- TFLite GPU delegate (optional, improves inference speed) -->
<uses-feature android:glEsVersion="0x00030001" android:required="false" />
```

---

## Checklist

- [ ] `activity_tracker.tflite` copied to both `assets/model/` and `android/app/src/main/assets/`
- [ ] `assets/model/activity_tracker.tflite` declared in `pubspec.yaml` under `flutter.assets`
- [ ] `tflite_flutter: ^0.12.1` in `pubspec.yaml`
- [ ] `sensors_plus: ^4.0.2` in `pubspec.yaml` (if using phone accelerometer)
- [ ] `heart_bpm: ^2.0.0+0` in `pubspec.yaml` (if using phone camera BPM)
- [ ] All 10 Dart files copied with package import prefix updated
- [ ] `TFLiteActivityClassifier.loadModel()` called before routing to `TrackerPage`
- [ ] `MultiProvider` hierarchy set up in `main.dart` (Platform → Data → Domain → Presentation)
- [ ] `StressAlertBanner` triggered when `activity.label == 'Stress'`
- [ ] (Optional) `HeartBpmAdapter.connectExternalStream()` wired to the watch bridge stream
- [ ] (Optional) `AccelSource.Watch` + `PhoneDataListener` set up if using Galaxy Watch data
- [ ] Tests copied from `test/features/activity_classifier/`
