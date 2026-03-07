plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.serialization") version "1.9.0"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flowfit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    lint {
        checkReleaseBuilds = false
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("pacebeats") {
            storeFile = file("pacebeats-release-v3.jks")
            storePassword = "d9\$Kf7!pVhLm2@QxR4&Zt1#W"
            keyAlias = "pacebeats_release_v3"
            keyPassword = "d9\$Kf7!pVhLm2@QxR4&Zt1#W"
        }
    }

    defaultConfig {
        applicationId = "com.example.flowfit"
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("pacebeats")
        }
        release {
            signingConfig = signingConfigs.getByName("pacebeats")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Samsung Health Sensor API
    implementation(files("libs/samsung-health-sensor-api-1.4.1.aar"))
    
    // AndroidX Health Services Client
    implementation("androidx.health:health-services-client:1.0.0-beta03")
    
    // Wear OS libraries
    implementation("androidx.wear:wear:1.3.0")
    implementation("com.google.android.support:wearable:2.9.0")
    // Include the Wearable runtime dependency at runtime so classes (e.g. WearableActivityController)
    // are present when plugins such as wearable_rotary or wear access them at runtime.
    implementation("com.google.android.wearable:wearable:2.9.0")
    
    // Wearable Data Layer API for watch-phone communication
    implementation("com.google.android.gms:play-services-wearable:18.1.0")
    
    // Kotlin Coroutines for async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    
    // Kotlin Serialization for JSON encoding/decoding
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")
    // Enable the desugaring support library for plugin compatibility (e.g., flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}