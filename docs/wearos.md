<?xml version="1.0" encoding="utf-8"?>

<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <uses-permission android:name="android.permission.BODY_SENSORS" />

    <uses-permission android:name="android.permission.health.READ_HEART_RATE" />

    <uses-feature android:name="android.hardware.type.watch" />

    <application

        android:name=".TheApp"

        android:allowBackup="true"

        android:icon="@mipmap/ic_launcher"

        android:label="@string/app_name"

        android:supportsRtl="true"

        android:theme="@android:style/Theme.DeviceDefault">

        <uses-library

            android:name="com.google.android.wearable"

            android:required="true" />

        <!--

               Set to true if your app is Standalone, that is, it does not require the handheld

               app to run.

        -->

        <meta-data

            android:name="com.google.android.wearable.standalone"

            android:value="true" />

        <activity

            android:name=".presentation.MainActivity"

            android:exported="true"

            android:taskAffinity=""

            android:theme="@android:style/Theme.DeviceDefault">

            <intent-filter>

                <action android:name="android.intent.action.MAIN" />

                <category android:name="android.intent.category.LAUNCHER" />

            </intent-filter>

        </activity>

    </application>

</manifest>

check this wearos setup preorely and tr to cmparethe diferene witth the native kotlin lyae rfo rh te smarwtach 

package com.Pulsify.domain

import com.Pulsify.data.TrackingRepository
import javax.inject.Inject

class AreTrackingCapabilitiesAvailableUseCase @Inject constructor(
    private val trackingRepository: TrackingRepository
) {
    operator fun invoke(): Boolean {
        return trackingRepository.hasCapabilities()
    }
}

package com.Pulsify.domain

import com.google.android.gms.wearable.Node
import com.Pulsify.data.CapabilityRepository
import javax.inject.Inject

private const val CAPABILITY = "wear"

class GetCapableNodes @Inject constructor(
    private val capabilityRepository: CapabilityRepository
) {
    suspend operator fun invoke(): Set<Node> {
        return capabilityRepository.getNodesForCapability(
            CAPABILITY,
            capabilityRepository.getCapabilitiesForReachableNodes()
        )
    }
}

package com.Pulsify.domain

import com.Pulsify.data.ConnectionMessage
import com.Pulsify.data.HealthTrackingServiceConnection
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject


class MakeConnectionToHealthTrackingServiceUseCase @OptIn(ExperimentalCoroutinesApi::class)
@Inject constructor(
    private val healthTrackingServiceConnection: HealthTrackingServiceConnection
) {
    @OptIn(ExperimentalCoroutinesApi::class)
    operator fun invoke(): Flow<ConnectionMessage> = healthTrackingServiceConnection.connectionFlow

}


package com.Pulsify.domain

import android.util.Log
import com.Pulsify.data.TrackedData
import com.Pulsify.data.MessageRepository
import com.Pulsify.data.TrackingRepository
import kotlinx.serialization.json.Json
import javax.inject.Inject

private const val TAG = "SendMessageUseCase"

private const val MESSAGE_PATH = "/msg"

class SendMessageUseCase @Inject constructor(
    private val messageRepository: MessageRepository,
    private val trackingRepository: TrackingRepository,
    private val getCapableNodes: GetCapableNodes
) {
    suspend operator fun invoke(): Boolean {

        val nodes = getCapableNodes()

        return if (nodes.isNotEmpty()) {

            val node = nodes.first()
            val message =
                encodeMessage(trackingRepository.getValidHrData())
            messageRepository.sendMessage(message, node, MESSAGE_PATH)

            true

        } else {
            Log.i(TAG, "Ain't no nodes around")
            false
        }
    }

    fun encodeMessage(trackedData: ArrayList<TrackedData>): String {

        return Json.encodeToString(trackedData)
    }
}
package com.Pulsify.domain

import com.Pulsify.data.TrackingRepository
import javax.inject.Inject

class StopTrackingUseCase @Inject constructor(
    private val trackingRepository: TrackingRepository
) {
    operator fun invoke() {
        trackingRepository.stopTracking()
    }
}

package com.Pulsify.domain

import com.Pulsify.data.TrackerMessage
import com.Pulsify.data.TrackingRepository
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class TrackHeartRateUseCase
@Inject constructor(
    private val trackingRepository: TrackingRepository
) {
    suspend operator fun invoke(): Flow<TrackerMessage> = trackingRepository.track()
}

package com.Pulsify.presentation.ui

import android.util.Log
import android.widget.Toast
import android.widget.Toast.makeText
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.CircularProgressIndicator
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import com.Pulsify.R
import com.Pulsify.presentation.theme.HRDataTransferTheme

private const val TAG = "MainScreen"

@Composable
fun MainScreen(
    connected: Boolean,
    connectionMessage: String,
    trackingRunning: Boolean,
    trackingError: Boolean,
    trackingMessage: String,
    valueHR: String,
    valueIBI: ArrayList<Int>,
    onStart: () -> Unit,
    onStop: () -> Unit,
    onSend: () -> Unit
) {
    Log.i(TAG, "MainScreen Composable")
    HRDataTransferTheme {
        ShowConnectionMessage(connected = connected, connectionMessage = connectionMessage)
        if (trackingMessage != "") ShowToast(trackingMessage)

        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.width(90.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    color = Color.LightGray,
                    text = "HR",
                    fontSize = 11.sp,
                )
                Spacer(modifier = Modifier.size(5.dp))
                Text(
                    color = Color.White,
                    text = valueHR,
                    fontSize = 40.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.size(11.dp))
                Box(
                    modifier = Modifier.size(54.dp)
                ) {
                    var startButtonPressed by remember { mutableStateOf(false) }
                    Button(
                        onClick = {
                            startButtonPressed = if (trackingRunning) {
                                onStop.invoke()
                                false
                            } else {
                                onStart.invoke()
                                true
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = if (trackingRunning) MaterialTheme.colors.primaryVariant else MaterialTheme.colors.primary
                        ),
                        enabled = connected,
                        modifier = Modifier
                            .size(54.dp),
                    ) {
                        Text(
                            textAlign = TextAlign.Center,
                            fontSize = 11.sp,
                            color = MaterialTheme.colors.onSecondary,
                            text = if (trackingRunning) stringResource(R.string.stop_button)
                            else stringResource(
                                R.string.start_button
                            ),
                        )
                    }
                    if (!trackingError && !trackingRunning && startButtonPressed) {
                        CircularProgressIndicator(
                            modifier = Modifier.fillMaxSize(),
                            indicatorColor = Color.Black,
                            strokeWidth = 4.dp
                        )
                    }
                }
            }
            Spacer(Modifier.size(2.dp))
            Column(
                modifier = Modifier.width(90.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    color = Color.LightGray,
                    text = "IBI",
                    fontSize = 11.sp,
                    textAlign = TextAlign.Right
                )
                Spacer(modifier = Modifier.size(5.dp))
                Text(
                    color = Color.White,
                    text = valueIBI.getOrElse(0) { "-" }.toString(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    color = Color.White,
                    text = valueIBI.getOrElse(1) { "-" }.toString(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    color = Color.White,
                    text = valueIBI.getOrElse(2) { "-" }.toString(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    color = Color.White,
                    text = valueIBI.getOrElse(3) { "-" }.toString(),
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                )
                Spacer(Modifier.size(11.dp))
                Button(
                    onClick = onSend,
                    colors = ButtonDefaults.buttonColors(
                        backgroundColor = MaterialTheme.colors.secondary
                    ),
                    enabled = connected,
                    modifier = Modifier
                        .size(52.dp)
                ) {
                    Text(
                        fontSize = 11.sp,
                        color = MaterialTheme.colors.onSecondary,
                        text = "SEND",
                    )
                }
            }
        }
    }
}

@Composable
fun ShowConnectionMessage(
    connected: Boolean,
    connectionMessage: String
) {
    Log.i(TAG, "connectionMessage: $connectionMessage, connected: $connected")
    if (connectionMessage != "" && connected) {
        ShowToast(connectionMessage)
    }
}

@Composable
fun ShowToast(message: String) {
    makeText(LocalContext.current, message, Toast.LENGTH_SHORT).show()
}
package com.Pulsify.presentation.ui

import android.health.connect.HealthPermissions
import android.os.Build
import android.util.Log
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.wear.compose.material.Text
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.Pulsify.R


private const val TAG = "Permission"

@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun Permission(
    onPermissionGranted: @Composable () -> Unit,
) {
    val permissionList: MutableList<String> = ArrayList()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
        permissionList.add(HealthPermissions.READ_HEART_RATE)
    } else {
        permissionList.add(android.Manifest.permission.BODY_SENSORS)
    }
    val bodySensorPermissionState = rememberMultiplePermissionsState(permissionList)
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(key1 = lifecycleOwner, effect = {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> {
                    Log.i(TAG, "Lifecycle.Event.ON_START")
                    bodySensorPermissionState.launchMultiplePermissionRequest()
                }

                else -> {
                }
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)

        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    })

    if (bodySensorPermissionState.allPermissionsGranted) {
        onPermissionGranted()
    } else {
        Row(
            Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            val textToShow = if (bodySensorPermissionState.shouldShowRationale) {
                stringResource(R.string.permission_should_show_rationale)
            } else {
                stringResource(R.string.permission_permanently_denied)
            }
            Text(
                modifier = Modifier.width(180.dp),
                textAlign = TextAlign.Center,
                fontSize = 13.sp,
                text = textToShow
            )
        }
    }
}

package com.Pulsify.presentation

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.Pulsify.R
import com.Pulsify.presentation.ui.MainScreen
import com.Pulsify.presentation.ui.Permission
import dagger.hilt.android.AndroidEntryPoint

private const val TAG = "MainActivity"

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val viewModel by viewModels<MainViewModel>()

    @SuppressLint("VisibleForTests")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            val trackingState by viewModel.trackingState.collectAsStateWithLifecycle()
            val connectionState by viewModel.connectionState.collectAsStateWithLifecycle()
            if (trackingState.trackingRunning) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
            LaunchedEffect(Unit) {
                viewModel
                    .messageSentToast
                    .collect { message ->
                        Toast.makeText(
                            applicationContext,
                            if (message) R.string.sending_success else R.string.sending_failed,
                            Toast.LENGTH_SHORT,
                        ).show()
                    }
            }
            Log.i(
                TAG, "connected: ${connectionState.connected}, " +
                        "message: ${connectionState.message}, " +
                        "connectionException: ${connectionState.connectionException}"
            )
            connectionState.connectionException?.resolve(this)
            Permission {
                MainScreen(
                    connectionState.connected,
                    connectionState.message,
                    trackingState.trackingRunning,
                    trackingState.trackingError,
                    trackingState.message,
                    trackingState.valueHR,
                    trackingState.valueIBI,
                    { viewModel.startTracking(); Log.i(TAG, "startTracking()") },
                    { viewModel.stopTracking(); Log.i(TAG, "stopTracking()") },
                    { viewModel.sendMessage(); Log.i(TAG, "sendMessage()") })
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (!viewModel.connectionState.value.connected) {
            viewModel.setUpTracking()
        }
    }
}

it has this common bfodler too
package com.Pulsify.data

import kotlinx.serialization.Serializable

@Serializable
data class TrackedData(
    var hr: Int = 0,
    var ibi: ArrayList<Int> = ArrayList()
)

<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    tools:ignore="LockedOrientationActivity">

    <application
        android:name="com.Pulsify.mobile.MobileApp"
        android:allowBackup="true"
        android:fullBackupOnly="true"
        android:icon="@drawable/ic_launcher"
        android:label="@string/app_name">
        <service
            android:name="com.Pulsify.mobile.data.DataListenerService"
            android:exported="true">

            <intent-filter>
                <action android:name="com.google.android.gms.wearable.DATA_CHANGED" />
                <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
                <action android:name="com.google.android.gms.wearable.REQUEST_RECEIVED" />
                <action android:name="com.google.android.gms.wearable.CAPABILITY_CHANGED" />
                <action android:name="com.google.android.gms.wearable.CHANNEL_EVENT" />

                <data
                    android:host="*"
                    android:pathPrefix="/msg"
                    android:scheme="wear" />
            </intent-filter>
        </service>
        <activity
            android:name="com.Pulsify.mobile.presentation.MainActivity"
            android:configChanges="orientation|keyboardHidden"
            android:exported="true"
            android:launchMode="singleTask"
            android:screenOrientation="portrait"
            android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen"
            tools:ignore="DiscouragedApi">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>

and this is the mobiel setup 

package com.Pulsify.presentation

import com.Pulsify.data.TrackedData
import kotlinx.serialization.json.Json

class HelpFunctions {

    companion object {
        fun decodeMessage(message: String): List<TrackedData> {

            return Json.decodeFromString(message)
        }
    }
}

package com.Pulsify.presentation

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import com.Pulsify.presentation.ui.MainScreen
import dagger.hilt.android.AndroidEntryPoint

private const val TAG = "MainActivity"

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { TheApp(intent) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setContent { TheApp(intent) }
    }

    override fun onResume() {
        super.onResume()
        Log.i(TAG, "onResume()")
    }
}

@Composable
fun TheApp(intent: Intent?) {
    if (intent?.getStringExtra("message") != null) {
        val txt = intent.getStringExtra("message").toString()

        val measurementResults = HelpFunctions.decodeMessage(txt)
        MainScreen(measurementResults)
    }
}
package com.Pulsify.mobile.data

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import com.Pulsify.mobile.presentation.MainActivity

private const val TAG = "DataListenerService"
private const val MESSAGE_PATH = "/msg"

class DataListenerService : WearableListenerService() {

    override fun onMessageReceived(messageEvent: MessageEvent) {
        super.onMessageReceived(messageEvent)

        val value = messageEvent.data.decodeToString()
        Log.i(TAG, "onMessageReceived(): $value")
        when (messageEvent.path) {
            MESSAGE_PATH -> {
                Log.i(TAG, "Service: message (/msg) received: $value")

                if (value != "") {
                    startActivity(
                        Intent(this, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).putExtra("message", value)
                    )
                } else {
                    Log.i(TAG, "value is an empty string")
                }
            }
        }
    }
}

