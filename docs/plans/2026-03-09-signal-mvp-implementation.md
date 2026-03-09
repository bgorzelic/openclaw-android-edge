# SIGNAL MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the SIGNAL Android app MVP — WiFi scanner, syslog receiver, Cisco WLC parser, roaming timeline, OpenClaw AI triage, log import, and setup wizard.

**Architecture:** Native Kotlin/Jetpack Compose app with Hilt DI, Room local DB, Ktor UDP sockets for syslog, OkHttp for OpenClaw REST API. MVVM pattern with Kotlin Flow for reactive data.

**Tech Stack:** Kotlin 2.0, Jetpack Compose (Material 3), Hilt, Room, Ktor (raw sockets), OkHttp, Kotlin Coroutines/Flow, JUnit 5, Compose Testing

**Design Doc:** [SIGNAL Product Design](2026-03-09-signal-product-design.md)

---

## Task 1: Project Scaffolding

**Goal:** Create new Android project with all dependencies, basic app shell, and CI-ready structure.

**Files:**
- Create: `signal-app/` (new repo root)
- Create: `signal-app/app/src/main/java/dev/aiaerial/signal/SignalApplication.kt`
- Create: `signal-app/app/src/main/java/dev/aiaerial/signal/MainActivity.kt`
- Create: `signal-app/app/src/main/java/dev/aiaerial/signal/di/AppModule.kt`
- Create: `signal-app/app/src/main/java/dev/aiaerial/signal/ui/theme/Theme.kt`
- Create: `signal-app/app/src/main/java/dev/aiaerial/signal/ui/navigation/SignalNavHost.kt`
- Create: `signal-app/app/src/main/AndroidManifest.xml`

**Step 1: Create the Android project via Android Studio**

Open Android Studio → New Project → Empty Activity (Compose) with these settings:
- Name: `SIGNAL`
- Package: `dev.aiaerial.signal`
- Min SDK: API 29 (Android 10) — needed for WiFi scan APIs
- Build config: Kotlin DSL (build.gradle.kts)
- Language: Kotlin

**Step 2: Add dependencies to `app/build.gradle.kts`**

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.hilt.android)
    alias(libs.plugins.ksp)
}

android {
    namespace = "dev.aiaerial.signal"
    compileSdk = 35

    defaultConfig {
        applicationId = "dev.aiaerial.signal"
        minSdk = 29
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    // Compose BOM
    val composeBom = platform("androidx.compose:compose-bom:2025.05.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // Navigation
    implementation("androidx.navigation:navigation-compose:2.8.9")

    // ViewModel + Compose
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // Hilt
    implementation("com.google.dagger:hilt-android:2.54.1")
    ksp("com.google.dagger:hilt-compiler:2.54.1")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")

    // Room
    implementation("androidx.room:room-runtime:2.7.1")
    implementation("androidx.room:room-ktx:2.7.1")
    ksp("androidx.room:room-compiler:2.7.1")

    // Ktor (raw sockets for syslog UDP)
    implementation("io.ktor:ktor-network:3.1.1")

    // OkHttp (OpenClaw REST API)
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Kotlinx serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
    testImplementation("io.mockk:mockk:1.13.14")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

**Step 3: Add version catalog entries to `gradle/libs.versions.toml`**

```toml
[versions]
agp = "8.9.1"
kotlin = "2.1.10"
hilt = "2.54.1"
ksp = "2.1.10-1.0.31"

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
hilt-android = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
```

**Step 4: Create Application class with Hilt**

```kotlin
// app/src/main/java/dev/aiaerial/signal/SignalApplication.kt
package dev.aiaerial.signal

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class SignalApplication : Application()
```

**Step 5: Create MainActivity with Compose shell**

```kotlin
// app/src/main/java/dev/aiaerial/signal/MainActivity.kt
package dev.aiaerial.signal

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import dagger.hilt.android.AndroidEntryPoint
import dev.aiaerial.signal.ui.theme.SignalTheme
import dev.aiaerial.signal.ui.navigation.SignalNavHost

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            SignalTheme {
                SignalNavHost()
            }
        }
    }
}
```

**Step 6: Create navigation shell with bottom nav**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/navigation/SignalNavHost.kt
package dev.aiaerial.signal.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Wifi
import androidx.compose.material.icons.filled.Message
import androidx.compose.material.icons.filled.Timeline
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

enum class SignalScreen(val route: String, val label: String) {
    Scanner("scanner", "Scanner"),
    Syslog("syslog", "Syslog"),
    Timeline("timeline", "Timeline"),
    Settings("settings", "Settings"),
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignalNavHost() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    Scaffold(
        topBar = {
            TopAppBar(title = { Text("SIGNAL") })
        },
        bottomBar = {
            NavigationBar {
                val items = listOf(
                    SignalScreen.Scanner to Icons.Default.Wifi,
                    SignalScreen.Syslog to Icons.Default.Message,
                    SignalScreen.Timeline to Icons.Default.Timeline,
                    SignalScreen.Settings to Icons.Default.Settings,
                )
                items.forEach { (screen, icon) ->
                    NavigationBarItem(
                        icon = { Icon(icon, contentDescription = screen.label) },
                        label = { Text(screen.label) },
                        selected = currentRoute == screen.route,
                        onClick = {
                            navController.navigate(screen.route) {
                                popUpTo(SignalScreen.Scanner.route) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = SignalScreen.Scanner.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(SignalScreen.Scanner.route) {
                Text("WiFi Scanner — coming soon")
            }
            composable(SignalScreen.Syslog.route) {
                Text("Syslog Receiver — coming soon")
            }
            composable(SignalScreen.Timeline.route) {
                Text("Roaming Timeline — coming soon")
            }
            composable(SignalScreen.Settings.route) {
                Text("Settings — coming soon")
            }
        }
    }
}
```

**Step 7: Set permissions in AndroidManifest.xml**

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- WiFi scanning -->
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

    <!-- Syslog UDP receiver -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Foreground service for syslog -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application
        android:name=".SignalApplication"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="SIGNAL"
        android:supportsRtl="true"
        android:theme="@style/Theme.SIGNAL">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.SIGNAL">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

**Step 8: Build and run**

Run: `./gradlew assembleDebug`
Expected: BUILD SUCCESSFUL. App launches with 4-tab bottom nav, placeholder text on each tab.

**Step 9: Commit**

```bash
git init
git add -A
git commit -m "feat: scaffold SIGNAL Android app with Compose, Hilt, navigation shell"
```

---

## Task 2: Data Models and Room Database

**Goal:** Define the core `NetworkEvent` entity and Room database that all features write to and read from.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/model/NetworkEvent.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/model/EventType.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/model/Vendor.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/local/NetworkEventDao.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/local/SignalDatabase.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/local/Converters.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/di/DatabaseModule.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/model/NetworkEventTest.kt`

**Step 1: Write the failing test**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/model/NetworkEventTest.kt
package dev.aiaerial.signal.data.model

import org.junit.Assert.*
import org.junit.Test

class NetworkEventTest {

    @Test
    fun `create network event with all fields`() {
        val event = NetworkEvent(
            timestamp = 1710000000000L,
            eventType = EventType.ROAM,
            clientMac = "AA:BB:CC:DD:EE:FF",
            apName = "AP-Floor3-East",
            bssid = "00:11:22:33:44:55",
            channel = 36,
            rssi = -65,
            reasonCode = 0,
            vendor = Vendor.CISCO,
            rawMessage = "<134>Mar 9 12:00:00 wlc: *apfMsConnTask: ...client roamed",
            sessionId = "session-001"
        )
        assertEquals(EventType.ROAM, event.eventType)
        assertEquals("AA:BB:CC:DD:EE:FF", event.clientMac)
        assertEquals(Vendor.CISCO, event.vendor)
    }

    @Test
    fun `create network event with nullable fields`() {
        val event = NetworkEvent(
            timestamp = 1710000000000L,
            eventType = EventType.UNKNOWN,
            rawMessage = "some unparsed syslog line",
            sessionId = "session-001"
        )
        assertNull(event.clientMac)
        assertNull(event.apName)
        assertNull(event.bssid)
        assertNull(event.channel)
        assertNull(event.rssi)
        assertEquals(EventType.UNKNOWN, event.eventType)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.model.NetworkEventTest"`
Expected: FAIL — classes not found

**Step 3: Implement data models**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/model/EventType.kt
package dev.aiaerial.signal.data.model

enum class EventType {
    ROAM,
    AUTH,
    DEAUTH,
    ASSOC,
    DISASSOC,
    RF_CHANGE,
    SCAN_RESULT,
    UNKNOWN
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/model/Vendor.kt
package dev.aiaerial.signal.data.model

enum class Vendor {
    CISCO,
    ARUBA,
    MERAKI,
    RUCKUS,
    JUNIPER,
    GENERIC,
    ANDROID
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/model/NetworkEvent.kt
package dev.aiaerial.signal.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "network_events")
data class NetworkEvent(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val timestamp: Long,
    val eventType: EventType,
    val clientMac: String? = null,
    val apName: String? = null,
    val bssid: String? = null,
    val channel: Int? = null,
    val rssi: Int? = null,
    val reasonCode: Int? = null,
    val vendor: Vendor = Vendor.GENERIC,
    val rawMessage: String,
    val sessionId: String,
)
```

**Step 4: Run test to verify it passes**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.model.NetworkEventTest"`
Expected: PASS

**Step 5: Create Room DAO and Database**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/local/Converters.kt
package dev.aiaerial.signal.data.local

import androidx.room.TypeConverter
import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.Vendor

class Converters {
    @TypeConverter
    fun fromEventType(value: EventType): String = value.name

    @TypeConverter
    fun toEventType(value: String): EventType = EventType.valueOf(value)

    @TypeConverter
    fun fromVendor(value: Vendor): String = value.name

    @TypeConverter
    fun toVendor(value: String): Vendor = Vendor.valueOf(value)
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/local/NetworkEventDao.kt
package dev.aiaerial.signal.data.local

import androidx.room.*
import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.NetworkEvent
import kotlinx.coroutines.flow.Flow

@Dao
interface NetworkEventDao {

    @Insert
    suspend fun insert(event: NetworkEvent): Long

    @Insert
    suspend fun insertAll(events: List<NetworkEvent>)

    @Query("SELECT * FROM network_events WHERE sessionId = :sessionId ORDER BY timestamp DESC")
    fun getBySession(sessionId: String): Flow<List<NetworkEvent>>

    @Query("SELECT * FROM network_events WHERE sessionId = :sessionId AND eventType = :type ORDER BY timestamp DESC")
    fun getBySessionAndType(sessionId: String, type: EventType): Flow<List<NetworkEvent>>

    @Query("SELECT * FROM network_events WHERE sessionId = :sessionId AND clientMac = :mac ORDER BY timestamp ASC")
    fun getClientJourney(sessionId: String, mac: String): Flow<List<NetworkEvent>>

    @Query("SELECT * FROM network_events WHERE id = :id")
    suspend fun getById(id: Long): NetworkEvent?

    @Query("DELETE FROM network_events WHERE sessionId = :sessionId")
    suspend fun deleteSession(sessionId: String)

    @Query("SELECT DISTINCT clientMac FROM network_events WHERE sessionId = :sessionId AND clientMac IS NOT NULL")
    fun getDistinctClients(sessionId: String): Flow<List<String>>

    @Query("SELECT COUNT(*) FROM network_events WHERE sessionId = :sessionId")
    fun getEventCount(sessionId: String): Flow<Int>
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/local/SignalDatabase.kt
package dev.aiaerial.signal.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import dev.aiaerial.signal.data.model.NetworkEvent

@Database(entities = [NetworkEvent::class], version = 1, exportSchema = false)
@TypeConverters(Converters::class)
abstract class SignalDatabase : RoomDatabase() {
    abstract fun networkEventDao(): NetworkEventDao
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/di/DatabaseModule.kt
package dev.aiaerial.signal.di

import android.content.Context
import androidx.room.Room
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import dev.aiaerial.signal.data.local.NetworkEventDao
import dev.aiaerial.signal.data.local.SignalDatabase
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): SignalDatabase =
        Room.databaseBuilder(context, SignalDatabase::class.java, "signal.db")
            .build()

    @Provides
    fun provideNetworkEventDao(db: SignalDatabase): NetworkEventDao = db.networkEventDao()
}
```

**Step 6: Build to verify Room compilation**

Run: `./gradlew assembleDebug`
Expected: BUILD SUCCESSFUL (Room annotation processor generates implementation)

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add NetworkEvent data model, Room database, and DAO"
```

---

## Task 3: WiFi Scanner

**Goal:** Implement WiFi scanning using Android WifiManager API, display scan results in a list with signal strength, and show a real-time signal graph for the connected AP.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/wifi/WifiScanner.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/scanner/ScannerViewModel.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/scanner/ScannerScreen.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/scanner/WifiNetworkCard.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/scanner/SignalChart.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/di/WifiModule.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/wifi/WifiScannerTest.kt`

**Step 1: Write the failing test for WifiScanner wrapper**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/wifi/WifiScannerTest.kt
package dev.aiaerial.signal.data.wifi

import org.junit.Assert.*
import org.junit.Test

class WifiScannerTest {

    @Test
    fun `WifiScanResult maps from Android ScanResult correctly`() {
        val result = WifiScanResult(
            ssid = "CorpWiFi",
            bssid = "AA:BB:CC:DD:EE:FF",
            rssi = -55,
            frequency = 5180,
            channelWidth = 80,
            security = "WPA3",
            timestamp = 1710000000000L
        )
        assertEquals("CorpWiFi", result.ssid)
        assertEquals(36, result.channel) // 5180 MHz = channel 36
        assertEquals("5 GHz", result.band)
    }

    @Test
    fun `channel derived from frequency for 2_4 GHz`() {
        val result = WifiScanResult(
            ssid = "Guest", bssid = "00:00:00:00:00:00",
            rssi = -70, frequency = 2437, channelWidth = 20,
            security = "WPA2", timestamp = 0L
        )
        assertEquals(6, result.channel) // 2437 MHz = channel 6
        assertEquals("2.4 GHz", result.band)
    }

    @Test
    fun `channel derived from frequency for 6 GHz`() {
        val result = WifiScanResult(
            ssid = "WiFi6E", bssid = "00:00:00:00:00:00",
            rssi = -60, frequency = 5955, channelWidth = 160,
            security = "WPA3", timestamp = 0L
        )
        assertEquals(1, result.channel) // 6 GHz channel 1 = 5955 MHz
        assertEquals("6 GHz", result.band)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.wifi.WifiScannerTest"`
Expected: FAIL — class not found

**Step 3: Implement WifiScanResult data class with frequency-to-channel conversion**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/wifi/WifiScanResult.kt
package dev.aiaerial.signal.data.wifi

data class WifiScanResult(
    val ssid: String,
    val bssid: String,
    val rssi: Int,
    val frequency: Int,
    val channelWidth: Int,
    val security: String,
    val timestamp: Long,
) {
    val channel: Int
        get() = frequencyToChannel(frequency)

    val band: String
        get() = when {
            frequency < 3000 -> "2.4 GHz"
            frequency < 5900 -> "5 GHz"
            else -> "6 GHz"
        }

    companion object {
        fun frequencyToChannel(freq: Int): Int = when {
            freq in 2412..2484 -> (freq - 2407) / 5
            freq in 5170..5885 -> (freq - 5000) / 5
            freq >= 5955 -> (freq - 5950) / 5  // 6 GHz: UNII-5 starts at 5955
            else -> 0
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.wifi.WifiScannerTest"`
Expected: PASS

**Step 5: Implement WifiScanner wrapper**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/wifi/WifiScanner.kt
package dev.aiaerial.signal.data.wifi

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WifiScanner @Inject constructor(
    private val wifiManager: WifiManager,
    private val context: Context,
) {
    fun scanResults(): Flow<List<WifiScanResult>> = callbackFlow {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                val results = wifiManager.scanResults.map { sr ->
                    WifiScanResult(
                        ssid = sr.SSID ?: "(hidden)",
                        bssid = sr.BSSID ?: "",
                        rssi = sr.level,
                        frequency = sr.frequency,
                        channelWidth = sr.channelWidth,
                        security = extractSecurity(sr),
                        timestamp = sr.timestamp / 1000, // microseconds to millis
                    )
                }.sortedByDescending { it.rssi }
                trySend(results)
            }
        }

        context.registerReceiver(
            receiver,
            IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
        )

        // Trigger initial scan
        wifiManager.startScan()

        awaitClose { context.unregisterReceiver(receiver) }
    }

    fun triggerScan() {
        wifiManager.startScan()
    }

    fun connectionInfo(): WifiConnectionInfo? {
        val info = wifiManager.connectionInfo ?: return null
        if (info.bssid == null) return null
        return WifiConnectionInfo(
            ssid = info.ssid?.removeSurrounding("\"") ?: "",
            bssid = info.bssid ?: "",
            rssi = info.rssi,
            linkSpeed = info.linkSpeed,
            frequency = info.frequency,
            ipAddress = intToIp(info.ipAddress),
        )
    }

    private fun extractSecurity(sr: android.net.wifi.ScanResult): String {
        val caps = sr.capabilities ?: return "Open"
        return when {
            "WPA3" in caps -> "WPA3"
            "WPA2" in caps -> "WPA2"
            "WPA" in caps -> "WPA"
            "WEP" in caps -> "WEP"
            else -> "Open"
        }
    }

    private fun intToIp(ip: Int): String =
        "${ip and 0xFF}.${ip shr 8 and 0xFF}.${ip shr 16 and 0xFF}.${ip shr 24 and 0xFF}"
}

data class WifiConnectionInfo(
    val ssid: String,
    val bssid: String,
    val rssi: Int,
    val linkSpeed: Int,
    val frequency: Int,
    val ipAddress: String,
)
```

**Step 6: Create Hilt module for WiFi**

```kotlin
// app/src/main/java/dev/aiaerial/signal/di/WifiModule.kt
package dev.aiaerial.signal.di

import android.content.Context
import android.net.wifi.WifiManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
object WifiModule {

    @Provides
    fun provideWifiManager(@ApplicationContext context: Context): WifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    @Provides
    fun provideAppContext(@ApplicationContext context: Context): Context = context
}
```

**Step 7: Create ScannerViewModel**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/scanner/ScannerViewModel.kt
package dev.aiaerial.signal.ui.scanner

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dev.aiaerial.signal.data.wifi.WifiConnectionInfo
import dev.aiaerial.signal.data.wifi.WifiScanResult
import dev.aiaerial.signal.data.wifi.WifiScanner
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ScannerViewModel @Inject constructor(
    private val wifiScanner: WifiScanner,
) : ViewModel() {

    private val _scanResults = MutableStateFlow<List<WifiScanResult>>(emptyList())
    val scanResults: StateFlow<List<WifiScanResult>> = _scanResults.asStateFlow()

    private val _connectionInfo = MutableStateFlow<WifiConnectionInfo?>(null)
    val connectionInfo: StateFlow<WifiConnectionInfo?> = _connectionInfo.asStateFlow()

    private val _rssiHistory = MutableStateFlow<List<Pair<Long, Int>>>(emptyList())
    val rssiHistory: StateFlow<List<Pair<Long, Int>>> = _rssiHistory.asStateFlow()

    init {
        viewModelScope.launch {
            wifiScanner.scanResults().collect { results ->
                _scanResults.value = results
            }
        }

        // Poll connection info every 2 seconds for signal graph
        viewModelScope.launch {
            while (true) {
                val info = wifiScanner.connectionInfo()
                _connectionInfo.value = info
                if (info != null) {
                    val history = _rssiHistory.value.toMutableList()
                    history.add(System.currentTimeMillis() to info.rssi)
                    // Keep last 60 data points (2 minutes at 2s interval)
                    if (history.size > 60) history.removeFirst()
                    _rssiHistory.value = history
                }
                delay(2000)
            }
        }
    }

    fun triggerScan() {
        wifiScanner.triggerScan()
    }
}
```

**Step 8: Create ScannerScreen composable**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/scanner/ScannerScreen.kt
package dev.aiaerial.signal.ui.scanner

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun ScannerScreen(viewModel: ScannerViewModel = hiltViewModel()) {
    val scanResults by viewModel.scanResults.collectAsState()
    val connectionInfo by viewModel.connectionInfo.collectAsState()
    val rssiHistory by viewModel.rssiHistory.collectAsState()

    var permissionsGranted by remember { mutableStateOf(false) }
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        permissionsGranted = permissions.values.all { it }
    }

    LaunchedEffect(Unit) {
        permissionLauncher.launch(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_WIFI_STATE,
                Manifest.permission.CHANGE_WIFI_STATE,
            )
        )
    }

    Column(modifier = Modifier.fillMaxSize()) {
        // Connection info card
        connectionInfo?.let { info ->
            ConnectionCard(info = info)
        }

        // Signal strength chart
        if (rssiHistory.isNotEmpty()) {
            SignalChart(
                dataPoints = rssiHistory,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp)
                    .padding(horizontal = 16.dp)
            )
        }

        // Scan button
        Button(
            onClick = { viewModel.triggerScan() },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
        ) {
            Text("Scan WiFi Networks")
        }

        // Results count
        Text(
            "${scanResults.size} networks found",
            style = MaterialTheme.typography.labelMedium,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
        )

        // Scan results list
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(scanResults, key = { it.bssid }) { result ->
                WifiNetworkCard(result = result)
            }
        }
    }
}

@Composable
private fun ConnectionCard(info: WifiConnectionInfo) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Connected", style = MaterialTheme.typography.labelSmall)
            Text(info.ssid, style = MaterialTheme.typography.titleMedium)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("BSSID: ${info.bssid}", style = MaterialTheme.typography.bodySmall)
                Text("${info.rssi} dBm", style = MaterialTheme.typography.bodySmall)
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text("${info.linkSpeed} Mbps", style = MaterialTheme.typography.bodySmall)
                Text("${info.frequency} MHz", style = MaterialTheme.typography.bodySmall)
                Text(info.ipAddress, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}
```

**Step 9: Create WifiNetworkCard composable**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/scanner/WifiNetworkCard.kt
package dev.aiaerial.signal.ui.scanner

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import dev.aiaerial.signal.data.wifi.WifiScanResult

@Composable
fun WifiNetworkCard(result: WifiScanResult) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Signal strength indicator
            SignalStrengthIndicator(
                rssi = result.rssi,
                modifier = Modifier.size(40.dp)
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = result.ssid.ifEmpty { "(hidden)" },
                    style = MaterialTheme.typography.titleSmall
                )
                Text(
                    text = result.bssid,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${result.rssi} dBm",
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = "Ch ${result.channel} · ${result.band}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "${result.security} · ${result.channelWidth}MHz",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun SignalStrengthIndicator(rssi: Int, modifier: Modifier = Modifier) {
    val color = when {
        rssi >= -50 -> MaterialTheme.colorScheme.primary        // Excellent
        rssi >= -60 -> MaterialTheme.colorScheme.primary        // Good
        rssi >= -70 -> MaterialTheme.colorScheme.tertiary       // Fair
        else -> MaterialTheme.colorScheme.error                  // Poor
    }
    val label = when {
        rssi >= -50 -> "Excellent"
        rssi >= -60 -> "Good"
        rssi >= -70 -> "Fair"
        else -> "Poor"
    }
    Surface(
        modifier = modifier,
        shape = MaterialTheme.shapes.small,
        color = color.copy(alpha = 0.15f)
    ) {
        Box(contentAlignment = Alignment.Center) {
            Text(
                text = "${rssi}",
                style = MaterialTheme.typography.labelSmall,
                color = color
            )
        }
    }
}
```

**Step 10: Create SignalChart composable (Canvas-based RSSI over time)**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/scanner/SignalChart.kt
package dev.aiaerial.signal.ui.scanner

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp

@Composable
fun SignalChart(
    dataPoints: List<Pair<Long, Int>>,
    modifier: Modifier = Modifier,
) {
    val lineColor = MaterialTheme.colorScheme.primary

    Canvas(modifier = modifier.fillMaxSize()) {
        if (dataPoints.size < 2) return@Canvas

        val minRssi = -90f
        val maxRssi = -30f
        val rangeRssi = maxRssi - minRssi

        val path = Path()
        dataPoints.forEachIndexed { index, (_, rssi) ->
            val x = (index.toFloat() / (dataPoints.size - 1)) * size.width
            val y = size.height - ((rssi - minRssi) / rangeRssi * size.height)
            if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }

        drawPath(path, lineColor, style = Stroke(width = 2.dp.toPx()))

        // Draw threshold lines
        listOf(-50, -67, -80).forEach { threshold ->
            val y = size.height - ((threshold - minRssi) / rangeRssi * size.height)
            drawLine(
                color = Color.Gray.copy(alpha = 0.3f),
                start = Offset(0f, y),
                end = Offset(size.width, y),
                strokeWidth = 1.dp.toPx()
            )
        }
    }
}
```

**Step 11: Wire ScannerScreen into navigation**

Update `SignalNavHost.kt` — replace the Scanner placeholder:

```kotlin
// In the NavHost composable block, replace:
composable(SignalScreen.Scanner.route) {
    Text("WiFi Scanner — coming soon")
}
// With:
composable(SignalScreen.Scanner.route) {
    ScannerScreen()
}
```

**Step 12: Build and test on device**

Run: `./gradlew installDebug`
Expected: App installs, Scanner tab shows WiFi networks after granting location permission.

**Step 13: Commit**

```bash
git add -A
git commit -m "feat: add WiFi scanner with signal chart and network cards"
```

---

## Task 4: Syslog Receiver Service

**Goal:** Implement a UDP syslog listener as an Android foreground service. Incoming syslog messages are stored in Room and exposed as a Flow.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/syslog/SyslogReceiver.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/syslog/SyslogMessage.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/service/SyslogService.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/syslog/SyslogViewModel.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/syslog/SyslogScreen.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/syslog/SyslogMessageTest.kt`

**Step 1: Write failing test for SyslogMessage parsing**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/syslog/SyslogMessageTest.kt
package dev.aiaerial.signal.data.syslog

import org.junit.Assert.*
import org.junit.Test

class SyslogMessageTest {

    @Test
    fun `parse RFC 3164 syslog message`() {
        val raw = "<134>Mar  9 12:00:00 wlc-9800 apfMsConnTask: Client AA:BB:CC:DD:EE:FF associated to AP-Lobby"
        val msg = SyslogMessage.parse(raw)
        assertEquals(134, msg.priority)
        assertEquals(16, msg.facility) // 134 / 8
        assertEquals(6, msg.severity) // 134 % 8
        assertEquals("wlc-9800", msg.hostname)
        assertTrue(msg.message.contains("Client AA:BB:CC:DD:EE:FF"))
    }

    @Test
    fun `parse message without priority`() {
        val raw = "Mar  9 12:00:00 meraki-ap some event happened"
        val msg = SyslogMessage.parse(raw)
        assertEquals(-1, msg.priority)
        assertEquals(raw, msg.raw)
    }

    @Test
    fun `severity level string`() {
        assertEquals("info", SyslogMessage.severityName(6))
        assertEquals("warning", SyslogMessage.severityName(4))
        assertEquals("error", SyslogMessage.severityName(3))
        assertEquals("critical", SyslogMessage.severityName(2))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.syslog.SyslogMessageTest"`
Expected: FAIL

**Step 3: Implement SyslogMessage**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/syslog/SyslogMessage.kt
package dev.aiaerial.signal.data.syslog

data class SyslogMessage(
    val priority: Int,
    val facility: Int,
    val severity: Int,
    val hostname: String?,
    val message: String,
    val raw: String,
    val receivedAt: Long = System.currentTimeMillis(),
) {
    val severityLabel: String get() = severityName(severity)

    companion object {
        private val RFC3164 = Regex("""^<(\d{1,3})>(\w{3}\s+\d{1,2}\s\d{2}:\d{2}:\d{2})\s+(\S+)\s+(.*)$""")

        fun parse(raw: String): SyslogMessage {
            val match = RFC3164.find(raw)
            return if (match != null) {
                val pri = match.groupValues[1].toInt()
                SyslogMessage(
                    priority = pri,
                    facility = pri / 8,
                    severity = pri % 8,
                    hostname = match.groupValues[3],
                    message = match.groupValues[4],
                    raw = raw,
                )
            } else {
                SyslogMessage(
                    priority = -1,
                    facility = -1,
                    severity = -1,
                    hostname = null,
                    message = raw,
                    raw = raw,
                )
            }
        }

        fun severityName(severity: Int): String = when (severity) {
            0 -> "emergency"
            1 -> "alert"
            2 -> "critical"
            3 -> "error"
            4 -> "warning"
            5 -> "notice"
            6 -> "info"
            7 -> "debug"
            else -> "unknown"
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.syslog.SyslogMessageTest"`
Expected: PASS

**Step 5: Implement UDP SyslogReceiver using Ktor raw sockets**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/syslog/SyslogReceiver.kt
package dev.aiaerial.signal.data.syslog

import io.ktor.network.selector.*
import io.ktor.network.sockets.*
import io.ktor.utils.io.core.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class SyslogReceiver(
    private val port: Int = 1514,
) {
    private val _messages = MutableSharedFlow<SyslogMessage>(extraBufferCapacity = 256)
    val messages: SharedFlow<SyslogMessage> = _messages.asSharedFlow()

    private var job: Job? = null

    suspend fun start(scope: CoroutineScope) {
        val selectorManager = SelectorManager(Dispatchers.IO)
        val socket = aSocket(selectorManager).udp().bind(InetSocketAddress("0.0.0.0", port))

        job = scope.launch(Dispatchers.IO) {
            try {
                while (isActive) {
                    val datagram = socket.receive()
                    val raw = datagram.packet.readText()
                    val message = SyslogMessage.parse(raw.trim())
                    _messages.emit(message)
                }
            } finally {
                socket.close()
                selectorManager.close()
            }
        }
    }

    fun stop() {
        job?.cancel()
        job = null
    }
}
```

**Step 6: Implement SyslogService as a foreground service**

```kotlin
// app/src/main/java/dev/aiaerial/signal/service/SyslogService.kt
package dev.aiaerial.signal.service

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import dagger.hilt.android.AndroidEntryPoint
import dev.aiaerial.signal.MainActivity
import dev.aiaerial.signal.R
import dev.aiaerial.signal.data.syslog.SyslogMessage
import dev.aiaerial.signal.data.syslog.SyslogReceiver
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.SharedFlow
import javax.inject.Inject

@AndroidEntryPoint
class SyslogService : Service() {

    private val receiver = SyslogReceiver(port = 1514)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    val messages: SharedFlow<SyslogMessage> get() = receiver.messages

    inner class LocalBinder : Binder() {
        val service: SyslogService get() = this@SyslogService
    }

    private val binder = LocalBinder()

    override fun onBind(intent: Intent): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground()
        scope.launch { receiver.start(scope) }
        return START_STICKY
    }

    private fun startForeground() {
        val channelId = "syslog_receiver"
        val channel = NotificationChannel(
            channelId, "Syslog Receiver",
            NotificationManager.IMPORTANCE_LOW
        )
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("SIGNAL Syslog Receiver")
            .setContentText("Listening on UDP port 1514")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(1, notification)
        }
    }

    override fun onDestroy() {
        receiver.stop()
        scope.cancel()
        super.onDestroy()
    }
}
```

**Step 7: Register service in AndroidManifest.xml**

Add inside `<application>`:

```xml
<service
    android:name=".service.SyslogService"
    android:exported="false"
    android:foregroundServiceType="specialUse" />
```

**Step 8: Create SyslogViewModel**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/syslog/SyslogViewModel.kt
package dev.aiaerial.signal.ui.syslog

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import dev.aiaerial.signal.data.syslog.SyslogMessage
import dev.aiaerial.signal.service.SyslogService
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SyslogViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
) : ViewModel() {

    private val _messages = MutableStateFlow<List<SyslogMessage>>(emptyList())
    val messages: StateFlow<List<SyslogMessage>> = _messages.asStateFlow()

    private val _isRunning = MutableStateFlow(false)
    val isRunning: StateFlow<Boolean> = _isRunning.asStateFlow()

    private val _filterText = MutableStateFlow("")
    val filterText: StateFlow<String> = _filterText.asStateFlow()

    private var service: SyslogService? = null
    private val allMessages = mutableListOf<SyslogMessage>()

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
            service = (binder as SyslogService.LocalBinder).service
            _isRunning.value = true
            viewModelScope.launch {
                service?.messages?.collect { msg ->
                    allMessages.add(0, msg) // newest first
                    if (allMessages.size > 5000) allMessages.removeLast()
                    applyFilter()
                }
            }
        }

        override fun onServiceDisconnected(name: ComponentName) {
            service = null
            _isRunning.value = false
        }
    }

    fun startListening() {
        val intent = Intent(context, SyslogService::class.java)
        context.startForegroundService(intent)
        context.bindService(intent, connection, Context.BIND_AUTO_CREATE)
    }

    fun stopListening() {
        context.unbindService(connection)
        context.stopService(Intent(context, SyslogService::class.java))
        service = null
        _isRunning.value = false
    }

    fun setFilter(text: String) {
        _filterText.value = text
        applyFilter()
    }

    private fun applyFilter() {
        val filter = _filterText.value
        _messages.value = if (filter.isBlank()) {
            allMessages.toList()
        } else {
            allMessages.filter { it.raw.contains(filter, ignoreCase = true) }
        }
    }

    fun clearMessages() {
        allMessages.clear()
        _messages.value = emptyList()
    }
}
```

**Step 9: Create SyslogScreen composable**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/syslog/SyslogScreen.kt
package dev.aiaerial.signal.ui.syslog

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import dev.aiaerial.signal.data.syslog.SyslogMessage
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun SyslogScreen(
    viewModel: SyslogViewModel = hiltViewModel(),
    onEventTap: (SyslogMessage) -> Unit = {},
) {
    val messages by viewModel.messages.collectAsState()
    val isRunning by viewModel.isRunning.collectAsState()
    val filterText by viewModel.filterText.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        // Controls row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(
                onClick = {
                    if (isRunning) viewModel.stopListening() else viewModel.startListening()
                }
            ) {
                Text(if (isRunning) "Stop" else "Start Listening")
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = if (isRunning) "UDP :1514 active" else "Stopped",
                style = MaterialTheme.typography.bodySmall,
                color = if (isRunning) MaterialTheme.colorScheme.primary
                else MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.weight(1f))
            Text("${messages.size}", style = MaterialTheme.typography.labelLarge)
        }

        // Filter
        OutlinedTextField(
            value = filterText,
            onValueChange = { viewModel.setFilter(it) },
            placeholder = { Text("Filter messages...") },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            singleLine = true,
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Messages list
        LazyColumn(modifier = Modifier.fillMaxSize()) {
            items(messages, key = { "${it.receivedAt}-${it.raw.hashCode()}" }) { msg ->
                SyslogMessageRow(msg = msg, onClick = { onEventTap(msg) })
            }
        }
    }
}

@Composable
private fun SyslogMessageRow(msg: SyslogMessage, onClick: () -> Unit) {
    val timeFormat = remember { SimpleDateFormat("HH:mm:ss.SSS", Locale.US) }
    val severityColor = when {
        msg.severity <= 3 -> MaterialTheme.colorScheme.error
        msg.severity == 4 -> MaterialTheme.colorScheme.tertiary
        else -> MaterialTheme.colorScheme.onSurface
    }

    Surface(onClick = onClick) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 4.dp)
        ) {
            Row {
                Text(
                    text = timeFormat.format(Date(msg.receivedAt)),
                    style = MaterialTheme.typography.labelSmall,
                    fontFamily = FontFamily.Monospace,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = msg.severityLabel.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                    color = severityColor
                )
                msg.hostname?.let { host ->
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = host,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
            Text(
                text = msg.message,
                style = MaterialTheme.typography.bodySmall,
                fontFamily = FontFamily.Monospace,
                fontSize = 11.sp,
                maxLines = 3,
            )
        }
    }
    HorizontalDivider()
}
```

**Step 10: Wire SyslogScreen into navigation**

Update `SignalNavHost.kt` — replace the Syslog placeholder:

```kotlin
composable(SignalScreen.Syslog.route) {
    SyslogScreen()
}
```

**Step 11: Build and test on device**

Run: `./gradlew installDebug`
Then from a laptop on the same network: `echo "<134>Mar 9 12:00:00 test-wlc test: Hello SIGNAL" | nc -u <phone-ip> 1514`
Expected: Message appears in the Syslog tab.

**Step 12: Commit**

```bash
git add -A
git commit -m "feat: add syslog receiver service with UDP listener and live message display"
```

---

## Task 5: Cisco WLC Syslog Parser

**Goal:** Parse Cisco WLC (9800 and AireOS) syslog messages into normalized NetworkEvents. This is the core intelligence — extracting roaming, auth, deauth events from raw syslog.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/parser/VendorParser.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/parser/CiscoWlcParser.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/parser/VendorDetector.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/parser/CiscoWlcParserTest.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/parser/VendorDetectorTest.kt`

**Step 1: Write failing tests for CiscoWlcParser**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/parser/CiscoWlcParserTest.kt
package dev.aiaerial.signal.data.parser

import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.Vendor
import org.junit.Assert.*
import org.junit.Test

class CiscoWlcParserTest {

    private val parser = CiscoWlcParser()

    @Test
    fun `parse 9800 client roam event`() {
        val line = "*apfMsConnTask_6: Jun 15 14:23:45.123: %CLIENT_ORCH_LOG-6-CLIENT_ADDED_TO_RUN_STATE: " +
            "R0/0: wncd: Username entry (aa:bb:cc:dd:ee:ff) joined with ssid (CorpWiFi) " +
            "for device with AP name (AP-Floor3-East) AP mac (00:11:22:33:44:55) " +
            "channel (36) rssi (-62)"
        val event = parser.parse(line, "session-1")
        assertNotNull(event)
        assertEquals(EventType.ROAM, event!!.eventType)
        assertEquals("aa:bb:cc:dd:ee:ff", event.clientMac)
        assertEquals("AP-Floor3-East", event.apName)
        assertEquals(36, event.channel)
        assertEquals(-62, event.rssi)
        assertEquals(Vendor.CISCO, event.vendor)
    }

    @Test
    fun `parse AireOS client association`() {
        val line = "*apfMsConnTask_0: Mar 09 10:15:30.456: %DOT11-6-ASSOC: " +
            "Station aa:bb:cc:dd:ee:ff Associated MAP AP-Lobby slot 1"
        val event = parser.parse(line, "session-1")
        assertNotNull(event)
        assertEquals(EventType.ASSOC, event!!.eventType)
        assertEquals("aa:bb:cc:dd:ee:ff", event.clientMac)
        assertEquals("AP-Lobby", event.apName)
    }

    @Test
    fun `parse client deauthentication`() {
        val line = "*apfMsConnTask_2: Mar 09 10:20:00.789: %DOT11-6-DISASSOC: " +
            "Station aa:bb:cc:dd:ee:ff Disassociated MAP AP-Floor2 reason 8"
        val event = parser.parse(line, "session-1")
        assertNotNull(event)
        assertEquals(EventType.DISASSOC, event!!.eventType)
        assertEquals(8, event.reasonCode)
    }

    @Test
    fun `parse 802_1X auth failure`() {
        val line = "*emWeb: Mar 09 11:00:00.000: %DOT1X-3-AUTH_FAIL: " +
            "Authentication failed for client aa:bb:cc:dd:ee:ff reason TIMEOUT"
        val event = parser.parse(line, "session-1")
        assertNotNull(event)
        assertEquals(EventType.AUTH, event!!.eventType)
        assertEquals("aa:bb:cc:dd:ee:ff", event.clientMac)
    }

    @Test
    fun `return null for non-wifi syslog`() {
        val line = "<134>Mar 09 12:00:00 switch: %SYS-5-CONFIG_I: Configured from console"
        val event = parser.parse(line, "session-1")
        assertNull(event)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.parser.CiscoWlcParserTest"`
Expected: FAIL

**Step 3: Implement VendorParser interface and CiscoWlcParser**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/parser/VendorParser.kt
package dev.aiaerial.signal.data.parser

import dev.aiaerial.signal.data.model.NetworkEvent

interface VendorParser {
    fun canParse(line: String): Boolean
    fun parse(line: String, sessionId: String): NetworkEvent?
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/parser/CiscoWlcParser.kt
package dev.aiaerial.signal.data.parser

import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.NetworkEvent
import dev.aiaerial.signal.data.model.Vendor

class CiscoWlcParser : VendorParser {

    // Patterns for Cisco WLC syslog messages
    private val MAC_PATTERN = """([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2})""".toRegex(RegexOption.IGNORE_CASE)
    private val AP_NAME_PATTERN = """AP\s+(?:name\s+\(|)([A-Za-z0-9_\-]+)\)?""".toRegex(RegexOption.IGNORE_CASE)
    private val CHANNEL_PATTERN = """channel\s+\(?(\d+)\)?""".toRegex(RegexOption.IGNORE_CASE)
    private val RSSI_PATTERN = """rssi\s+\(?(-?\d+)\)?""".toRegex(RegexOption.IGNORE_CASE)
    private val REASON_PATTERN = """reason\s+(\d+)""".toRegex(RegexOption.IGNORE_CASE)

    // Event type detection patterns
    private val CLIENT_ADDED = """CLIENT_ADDED_TO_RUN_STATE|joined with ssid""".toRegex(RegexOption.IGNORE_CASE)
    private val ASSOC = """%DOT11-\d-ASSOC|Associated MAP""".toRegex(RegexOption.IGNORE_CASE)
    private val DISASSOC = """%DOT11-\d-DISASSOC|Disassociated""".toRegex(RegexOption.IGNORE_CASE)
    private val DEAUTH = """%DOT11-\d-DEAUTH|Deauthenticated|DEAUTHENTICATION""".toRegex(RegexOption.IGNORE_CASE)
    private val AUTH_FAIL = """%DOT1X-\d-AUTH_FAIL|Authentication failed""".toRegex(RegexOption.IGNORE_CASE)

    // Cisco-specific indicators
    private val CISCO_INDICATORS = """apfMsConnTask|%DOT11|%DOT1X|%CLIENT_ORCH|wncd:|capwap""".toRegex(RegexOption.IGNORE_CASE)

    override fun canParse(line: String): Boolean = CISCO_INDICATORS.containsMatchIn(line)

    override fun parse(line: String, sessionId: String): NetworkEvent? {
        if (!canParse(line)) return null

        val eventType = detectEventType(line) ?: return null
        val clientMac = MAC_PATTERN.find(line)?.groupValues?.get(1)
        val apName = extractApName(line)
        val channel = CHANNEL_PATTERN.find(line)?.groupValues?.get(1)?.toIntOrNull()
        val rssi = RSSI_PATTERN.find(line)?.groupValues?.get(1)?.toIntOrNull()
        val reasonCode = REASON_PATTERN.find(line)?.groupValues?.get(1)?.toIntOrNull()

        return NetworkEvent(
            timestamp = System.currentTimeMillis(),
            eventType = eventType,
            clientMac = clientMac,
            apName = apName,
            channel = channel,
            rssi = rssi,
            reasonCode = reasonCode,
            vendor = Vendor.CISCO,
            rawMessage = line,
            sessionId = sessionId,
        )
    }

    private fun detectEventType(line: String): EventType? = when {
        CLIENT_ADDED.containsMatchIn(line) -> EventType.ROAM
        DEAUTH.containsMatchIn(line) -> EventType.DEAUTH
        DISASSOC.containsMatchIn(line) -> EventType.DISASSOC
        ASSOC.containsMatchIn(line) -> EventType.ASSOC
        AUTH_FAIL.containsMatchIn(line) -> EventType.AUTH
        else -> null
    }

    private fun extractApName(line: String): String? {
        // Try "AP name (Foo)" pattern first
        val nameInParens = """AP\s+name\s+\(([^)]+)\)""".toRegex(RegexOption.IGNORE_CASE).find(line)
        if (nameInParens != null) return nameInParens.groupValues[1]

        // Try "MAP AP-Name" pattern (AireOS)
        val mapPattern = """MAP\s+([A-Za-z0-9_\-]+)""".toRegex().find(line)
        if (mapPattern != null) return mapPattern.groupValues[1]

        return null
    }
}
```

**Step 4: Run test to verify it passes**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.parser.CiscoWlcParserTest"`
Expected: PASS

**Step 5: Implement VendorDetector**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/parser/VendorDetector.kt
package dev.aiaerial.signal.data.parser

import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VendorDetector @Inject constructor() {

    private val parsers: List<VendorParser> = listOf(
        CiscoWlcParser(),
        // Future: ArubaParser(), MerakiParser(), etc.
    )

    fun parse(line: String, sessionId: String): dev.aiaerial.signal.data.model.NetworkEvent? {
        for (parser in parsers) {
            if (parser.canParse(line)) {
                return parser.parse(line, sessionId)
            }
        }
        return null
    }
}
```

**Step 6: Write and run VendorDetector test**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/parser/VendorDetectorTest.kt
package dev.aiaerial.signal.data.parser

import dev.aiaerial.signal.data.model.Vendor
import org.junit.Assert.*
import org.junit.Test

class VendorDetectorTest {

    private val detector = VendorDetector()

    @Test
    fun `detects Cisco and routes to CiscoWlcParser`() {
        val line = "*apfMsConnTask_6: Jun 15 14:23:45: %DOT11-6-ASSOC: " +
            "Station aa:bb:cc:dd:ee:ff Associated MAP AP-Lobby slot 1"
        val event = detector.parse(line, "s1")
        assertNotNull(event)
        assertEquals(Vendor.CISCO, event!!.vendor)
    }

    @Test
    fun `returns null for unknown vendor`() {
        val line = "some random log line that is not from any known vendor"
        assertNull(detector.parse(line, "s1"))
    }
}
```

Run: `./gradlew test --tests "dev.aiaerial.signal.data.parser.VendorDetectorTest"`
Expected: PASS

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Cisco WLC syslog parser with vendor detection framework"
```

---

## Task 6: Integrate Parser with Syslog Receiver + Persist Events

**Goal:** Connect the syslog receiver to the parser pipeline so incoming messages are automatically parsed and stored in Room.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/EventPipeline.kt`
- Modify: `app/src/main/java/dev/aiaerial/signal/service/SyslogService.kt`
- Modify: `app/src/main/java/dev/aiaerial/signal/ui/syslog/SyslogViewModel.kt`
- Modify: `app/src/main/java/dev/aiaerial/signal/ui/syslog/SyslogScreen.kt`

**Step 1: Create EventPipeline**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/EventPipeline.kt
package dev.aiaerial.signal.data

import dev.aiaerial.signal.data.local.NetworkEventDao
import dev.aiaerial.signal.data.model.NetworkEvent
import dev.aiaerial.signal.data.parser.VendorDetector
import dev.aiaerial.signal.data.syslog.SyslogMessage
import kotlinx.coroutines.flow.Flow
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EventPipeline @Inject constructor(
    private val vendorDetector: VendorDetector,
    private val dao: NetworkEventDao,
) {
    private var currentSessionId: String = UUID.randomUUID().toString()

    fun getSessionId(): String = currentSessionId

    fun newSession(): String {
        currentSessionId = UUID.randomUUID().toString()
        return currentSessionId
    }

    suspend fun processSyslogMessage(msg: SyslogMessage): NetworkEvent? {
        val event = vendorDetector.parse(msg.raw, currentSessionId)
        if (event != null) {
            dao.insert(event)
        }
        return event
    }

    suspend fun processLogBlock(text: String): List<NetworkEvent> {
        val events = text.lines()
            .mapNotNull { line -> vendorDetector.parse(line.trim(), currentSessionId) }
        if (events.isNotEmpty()) {
            dao.insertAll(events)
        }
        return events
    }

    fun eventsForCurrentSession(): Flow<List<NetworkEvent>> = dao.getBySession(currentSessionId)

    fun clientJourney(mac: String): Flow<List<NetworkEvent>> =
        dao.getClientJourney(currentSessionId, mac)

    fun distinctClients(): Flow<List<String>> = dao.getDistinctClients(currentSessionId)

    fun eventCount(): Flow<Int> = dao.getEventCount(currentSessionId)
}
```

**Step 2: Wire EventPipeline into SyslogService**

Update `SyslogService` to inject `EventPipeline` and process incoming messages:

Add to `SyslogService`:
```kotlin
@Inject lateinit var eventPipeline: EventPipeline

// In onStartCommand, after starting receiver:
scope.launch {
    receiver.messages.collect { msg ->
        eventPipeline.processSyslogMessage(msg)
    }
}
```

**Step 3: Update SyslogScreen to show parsed event count**

Add a row showing: "12 events parsed (3 roams, 2 auths, 7 other)" using `eventPipeline.eventCount()`.

**Step 4: Build and test**

Run: `./gradlew assembleDebug`
Expected: BUILD SUCCESSFUL

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: integrate syslog parser pipeline with Room persistence"
```

---

## Task 7: Roaming Timeline Screen

**Goal:** Visualize a client's roaming path across APs as a vertical timeline. User selects a client MAC, sees chronological list of AP transitions with timestamps, RSSI, and channel.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/ui/timeline/TimelineViewModel.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/timeline/TimelineScreen.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/timeline/RoamingTimelineCard.kt`

**Step 1: Create TimelineViewModel**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/timeline/TimelineViewModel.kt
package dev.aiaerial.signal.ui.timeline

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dev.aiaerial.signal.data.EventPipeline
import dev.aiaerial.signal.data.model.NetworkEvent
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TimelineViewModel @Inject constructor(
    private val pipeline: EventPipeline,
) : ViewModel() {

    val clients: StateFlow<List<String>> = pipeline.distinctClients()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _selectedClient = MutableStateFlow<String?>(null)
    val selectedClient: StateFlow<String?> = _selectedClient.asStateFlow()

    val clientEvents: StateFlow<List<NetworkEvent>> = _selectedClient
        .flatMapLatest { mac ->
            if (mac != null) pipeline.clientJourney(mac) else flowOf(emptyList())
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun selectClient(mac: String) {
        _selectedClient.value = mac
    }
}
```

**Step 2: Create TimelineScreen**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/timeline/TimelineScreen.kt
package dev.aiaerial.signal.ui.timeline

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.NetworkEvent
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimelineScreen(viewModel: TimelineViewModel = hiltViewModel()) {
    val clients by viewModel.clients.collectAsState()
    val selectedClient by viewModel.selectedClient.collectAsState()
    val events by viewModel.clientEvents.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        // Client picker
        if (clients.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = androidx.compose.ui.Alignment.Center
            ) {
                Text("No clients detected yet.\nStart the syslog receiver to capture roaming events.")
            }
        } else {
            Text(
                "Select client MAC:",
                style = MaterialTheme.typography.labelMedium,
                modifier = Modifier.padding(16.dp)
            )

            SingleChoiceSegmentedButtonRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                // Show as dropdown if > 5 clients
            }

            // Simple dropdown for client selection
            var expanded by remember { mutableStateOf(false) }
            ExposedDropdownMenuBox(
                expanded = expanded,
                onExpandedChange = { expanded = !expanded },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            ) {
                OutlinedTextField(
                    value = selectedClient ?: "Select a client...",
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                )
                ExposedDropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    clients.forEach { mac ->
                        DropdownMenuItem(
                            text = { Text(mac) },
                            onClick = {
                                viewModel.selectClient(mac)
                                expanded = false
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Timeline
            if (events.isNotEmpty()) {
                Text(
                    "${events.size} events",
                    style = MaterialTheme.typography.labelSmall,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )
            }

            LazyColumn(modifier = Modifier.fillMaxSize()) {
                items(events) { event ->
                    RoamingTimelineCard(event = event)
                }
            }
        }
    }
}
```

**Step 3: Create RoamingTimelineCard**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/timeline/RoamingTimelineCard.kt
package dev.aiaerial.signal.ui.timeline

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.unit.dp
import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.NetworkEvent
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun RoamingTimelineCard(event: NetworkEvent) {
    val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.US)
    val color = when (event.eventType) {
        EventType.ROAM -> MaterialTheme.colorScheme.primary
        EventType.ASSOC -> MaterialTheme.colorScheme.tertiary
        EventType.DISASSOC, EventType.DEAUTH -> MaterialTheme.colorScheme.error
        EventType.AUTH -> MaterialTheme.colorScheme.secondary
        else -> MaterialTheme.colorScheme.outline
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
    ) {
        // Timeline line + dot
        Canvas(
            modifier = Modifier
                .width(24.dp)
                .height(72.dp)
        ) {
            val centerX = size.width / 2
            // Vertical line
            drawLine(
                color = color.copy(alpha = 0.3f),
                start = Offset(centerX, 0f),
                end = Offset(centerX, size.height),
                strokeWidth = 2f
            )
            // Dot
            drawCircle(color = color, radius = 6f, center = Offset(centerX, size.height / 2))
        }

        Spacer(modifier = Modifier.width(8.dp))

        // Event details
        Card(
            modifier = Modifier
                .weight(1f)
                .padding(vertical = 4.dp)
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = event.eventType.name,
                        style = MaterialTheme.typography.labelMedium,
                        color = color
                    )
                    Text(
                        text = timeFormat.format(Date(event.timestamp)),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                event.apName?.let { ap ->
                    Text(text = ap, style = MaterialTheme.typography.titleSmall)
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    event.channel?.let { Text("Ch $it", style = MaterialTheme.typography.bodySmall) }
                    event.rssi?.let { Text("$it dBm", style = MaterialTheme.typography.bodySmall) }
                    event.reasonCode?.let { Text("Reason: $it", style = MaterialTheme.typography.bodySmall) }
                }
            }
        }
    }
}
```

**Step 4: Wire into navigation**

Update `SignalNavHost.kt`:
```kotlin
composable(SignalScreen.Timeline.route) {
    TimelineScreen()
}
```

**Step 5: Build and test**

Run: `./gradlew assembleDebug`
Expected: BUILD SUCCESSFUL

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add roaming timeline screen with client journey visualization"
```

---

## Task 8: OpenClaw Integration (AI Triage)

**Goal:** Connect to OpenClaw REST API on localhost:18789. Health check on startup. "Explain this event" feature — tap a syslog event, send to OpenClaw for AI analysis.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/openclaw/OpenClawClient.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/openclaw/OpenClawStatus.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/di/NetworkModule.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/triage/TriageBottomSheet.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/openclaw/OpenClawClientTest.kt`

**Step 1: Write failing test for OpenClaw request building**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/openclaw/OpenClawClientTest.kt
package dev.aiaerial.signal.data.openclaw

import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.NetworkEvent
import dev.aiaerial.signal.data.model.Vendor
import org.junit.Assert.*
import org.junit.Test

class OpenClawClientTest {

    @Test
    fun `buildTriagePrompt includes event details`() {
        val event = NetworkEvent(
            timestamp = 1710000000000L,
            eventType = EventType.DEAUTH,
            clientMac = "aa:bb:cc:dd:ee:ff",
            apName = "AP-Floor3",
            channel = 36,
            rssi = -75,
            reasonCode = 8,
            vendor = Vendor.CISCO,
            rawMessage = "original syslog line here",
            sessionId = "s1"
        )
        val prompt = OpenClawClient.buildTriagePrompt(event)
        assertTrue(prompt.contains("DEAUTH"))
        assertTrue(prompt.contains("aa:bb:cc:dd:ee:ff"))
        assertTrue(prompt.contains("AP-Floor3"))
        assertTrue(prompt.contains("reason code 8"))
        assertTrue(prompt.contains("-75 dBm"))
    }

    @Test
    fun `buildTriagePrompt asks for root cause`() {
        val event = NetworkEvent(
            timestamp = 0L,
            eventType = EventType.ROAM,
            rawMessage = "test",
            sessionId = "s1"
        )
        val prompt = OpenClawClient.buildTriagePrompt(event)
        assertTrue(prompt.contains("root cause") || prompt.contains("explain"))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.openclaw.OpenClawClientTest"`
Expected: FAIL

**Step 3: Implement OpenClawClient**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/openclaw/OpenClawStatus.kt
package dev.aiaerial.signal.data.openclaw

enum class OpenClawStatus {
    CONNECTED,
    DISCONNECTED,
    CHECKING,
}
```

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/openclaw/OpenClawClient.kt
package dev.aiaerial.signal.data.openclaw

import dev.aiaerial.signal.data.model.NetworkEvent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class OpenClawClient @Inject constructor(
    private val httpClient: OkHttpClient,
) {
    private var baseUrl = "http://127.0.0.1:18789"

    fun setBaseUrl(url: String) {
        baseUrl = url.trimEnd('/')
    }

    suspend fun healthCheck(): OpenClawStatus = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder().url("$baseUrl/").get().build()
            val response = httpClient.newCall(request).execute()
            if (response.isSuccessful) OpenClawStatus.CONNECTED else OpenClawStatus.DISCONNECTED
        } catch (_: IOException) {
            OpenClawStatus.DISCONNECTED
        }
    }

    suspend fun triageEvent(event: NetworkEvent): String = withContext(Dispatchers.IO) {
        val prompt = buildTriagePrompt(event)
        chat(
            systemPrompt = TRIAGE_SYSTEM_PROMPT,
            userMessage = prompt,
        )
    }

    suspend fun analyzeLogBlock(text: String): String = withContext(Dispatchers.IO) {
        chat(
            systemPrompt = LOG_ANALYSIS_SYSTEM_PROMPT,
            userMessage = "Analyze these wireless network log entries:\n\n$text",
        )
    }

    private fun chat(systemPrompt: String, userMessage: String): String {
        val body = buildJsonObject {
            putJsonArray("messages") {
                addJsonObject {
                    put("role", "system")
                    put("content", systemPrompt)
                }
                addJsonObject {
                    put("role", "user")
                    put("content", userMessage)
                }
            }
            put("model", "haiku")
            put("stream", false)
        }

        val request = Request.Builder()
            .url("$baseUrl/api/v1/chat")
            .post(body.toString().toRequestBody("application/json".toMediaType()))
            .build()

        val response = httpClient.newCall(request).execute()
        val responseBody = response.body?.string() ?: return "No response from OpenClaw"

        return try {
            val json = Json.parseToJsonElement(responseBody).jsonObject
            json["choices"]?.jsonArray?.firstOrNull()
                ?.jsonObject?.get("message")?.jsonObject?.get("content")?.jsonPrimitive?.content
                ?: responseBody
        } catch (_: Exception) {
            responseBody
        }
    }

    companion object {
        fun buildTriagePrompt(event: NetworkEvent): String = buildString {
            appendLine("Explain this wireless network event and suggest likely root cause:")
            appendLine()
            appendLine("Event type: ${event.eventType.name}")
            event.clientMac?.let { appendLine("Client MAC: $it") }
            event.apName?.let { appendLine("AP: $it") }
            event.bssid?.let { appendLine("BSSID: $it") }
            event.channel?.let { appendLine("Channel: $it") }
            event.rssi?.let { appendLine("Signal: $it dBm") }
            event.reasonCode?.let { appendLine("IEEE 802.11 reason code $it") }
            appendLine("Vendor: ${event.vendor.name}")
            appendLine()
            appendLine("Raw syslog:")
            appendLine(event.rawMessage)
        }

        private const val TRIAGE_SYSTEM_PROMPT = """You are SIGNAL's wireless network analysis engine. You help wireless network engineers understand network events.

When given a wireless event, provide:
1. A brief plain-English explanation of what happened
2. The likely root cause (top 2-3 possibilities)
3. Recommended next steps for the engineer

Keep responses concise (under 200 words). Use technical wireless terminology but explain acronyms on first use. Reference IEEE 802.11 reason/status codes when applicable."""

        private const val LOG_ANALYSIS_SYSTEM_PROMPT = """You are SIGNAL's wireless log analysis engine. Analyze wireless controller/AP log entries and identify:

1. Key events (roams, auths, deauths, RF changes)
2. Patterns or anomalies
3. Potential issues and root causes
4. Recommended actions

Group related events. Highlight anything unusual. Keep the analysis structured and actionable."""
    }
}
```

**Step 4: Run test to verify it passes**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.openclaw.OpenClawClientTest"`
Expected: PASS

**Step 5: Create Hilt NetworkModule**

```kotlin
// app/src/main/java/dev/aiaerial/signal/di/NetworkModule.kt
package dev.aiaerial.signal.di

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(5, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()
}
```

**Step 6: Create TriageBottomSheet composable**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/triage/TriageBottomSheet.kt
package dev.aiaerial.signal.ui.triage

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import dev.aiaerial.signal.data.model.NetworkEvent
import dev.aiaerial.signal.data.openclaw.OpenClawClient
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TriageBottomSheet(
    event: NetworkEvent,
    openClawClient: OpenClawClient,
    onDismiss: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var analysis by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(event) {
        isLoading = true
        analysis = try {
            openClawClient.triageEvent(event)
        } catch (e: Exception) {
            "Error: ${e.message}\n\nIs OpenClaw running on localhost:18789?"
        }
        isLoading = false
    }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {
            Text("AI Triage", style = MaterialTheme.typography.titleLarge)
            Spacer(modifier = Modifier.height(8.dp))

            // Event summary
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text("${event.eventType.name} — ${event.clientMac ?: "unknown client"}")
                    event.apName?.let { Text("AP: $it") }
                    Text(
                        event.rawMessage,
                        style = MaterialTheme.typography.bodySmall,
                        fontFamily = FontFamily.Monospace,
                        maxLines = 2
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Analysis
            if (isLoading) {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else {
                Text(
                    text = analysis ?: "No analysis available",
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}
```

**Step 7: Build**

Run: `./gradlew assembleDebug`
Expected: BUILD SUCCESSFUL

**Step 8: Commit**

```bash
git add -A
git commit -m "feat: add OpenClaw AI triage with health check and bottom sheet"
```

---

## Task 9: Log File Import Screen

**Goal:** Let engineers paste or import WLC debug output. Parse it through the vendor parser pipeline and display results.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/ui/import/LogImportViewModel.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/import/LogImportScreen.kt`
- Modify: `app/src/main/java/dev/aiaerial/signal/ui/navigation/SignalNavHost.kt`

**Step 1: Create LogImportViewModel**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/import/LogImportViewModel.kt
package dev.aiaerial.signal.ui.import

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dev.aiaerial.signal.data.EventPipeline
import dev.aiaerial.signal.data.model.NetworkEvent
import dev.aiaerial.signal.data.openclaw.OpenClawClient
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LogImportViewModel @Inject constructor(
    private val pipeline: EventPipeline,
    private val openClawClient: OpenClawClient,
) : ViewModel() {

    private val _logText = MutableStateFlow("")
    val logText: StateFlow<String> = _logText.asStateFlow()

    private val _parsedEvents = MutableStateFlow<List<NetworkEvent>>(emptyList())
    val parsedEvents: StateFlow<List<NetworkEvent>> = _parsedEvents.asStateFlow()

    private val _aiAnalysis = MutableStateFlow<String?>(null)
    val aiAnalysis: StateFlow<String?> = _aiAnalysis.asStateFlow()

    private val _isAnalyzing = MutableStateFlow(false)
    val isAnalyzing: StateFlow<Boolean> = _isAnalyzing.asStateFlow()

    fun setLogText(text: String) {
        _logText.value = text
    }

    fun parseLog() {
        viewModelScope.launch {
            val events = pipeline.processLogBlock(_logText.value)
            _parsedEvents.value = events
        }
    }

    fun analyzeWithAi() {
        viewModelScope.launch {
            _isAnalyzing.value = true
            _aiAnalysis.value = try {
                openClawClient.analyzeLogBlock(_logText.value)
            } catch (e: Exception) {
                "Error: ${e.message}"
            }
            _isAnalyzing.value = false
        }
    }

    fun clear() {
        _logText.value = ""
        _parsedEvents.value = emptyList()
        _aiAnalysis.value = null
    }
}
```

**Step 2: Create LogImportScreen**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/import/LogImportScreen.kt
package dev.aiaerial.signal.ui.import

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel

@Composable
fun LogImportScreen(viewModel: LogImportViewModel = hiltViewModel()) {
    val logText by viewModel.logText.collectAsState()
    val parsedEvents by viewModel.parsedEvents.collectAsState()
    val aiAnalysis by viewModel.aiAnalysis.collectAsState()
    val isAnalyzing by viewModel.isAnalyzing.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        Text("Import Logs", style = MaterialTheme.typography.titleMedium)
        Text(
            "Paste WLC debug output (e.g. 'debug client mac-address', show commands)",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = logText,
            onValueChange = { viewModel.setLogText(it) },
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp),
            placeholder = { Text("Paste log output here...") },
        )

        Spacer(modifier = Modifier.height(8.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Button(onClick = { viewModel.parseLog() }) {
                Text("Parse Events")
            }
            OutlinedButton(onClick = { viewModel.analyzeWithAi() }, enabled = !isAnalyzing) {
                Text(if (isAnalyzing) "Analyzing..." else "AI Analysis")
            }
            TextButton(onClick = { viewModel.clear() }) {
                Text("Clear")
            }
        }

        // Parsed events summary
        if (parsedEvents.isNotEmpty()) {
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                "${parsedEvents.size} events parsed",
                style = MaterialTheme.typography.titleSmall
            )
            parsedEvents.groupBy { it.eventType }.forEach { (type, events) ->
                Text("  ${type.name}: ${events.size}", style = MaterialTheme.typography.bodySmall)
            }
        }

        // AI analysis result
        aiAnalysis?.let { analysis ->
            Spacer(modifier = Modifier.height(16.dp))
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("AI Analysis", style = MaterialTheme.typography.titleSmall)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(analysis, style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}
```

**Step 3: Add import route to navigation**

Add `Import("import", "Import")` to `SignalScreen` enum and wire it into `SignalNavHost`. Add a FAB or menu item on the Syslog screen that navigates to the import screen.

**Step 4: Build and commit**

```bash
git add -A
git commit -m "feat: add log file import screen with AI analysis"
```

---

## Task 10: Settings Screen + OpenClaw Setup Wizard

**Goal:** Settings screen with OpenClaw connection configuration, health status indicator, and guided setup wizard for first-time users.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/ui/settings/SettingsViewModel.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/ui/settings/SettingsScreen.kt`
- Create: `app/src/main/java/dev/aiaerial/signal/data/prefs/SignalPreferences.kt`

**Step 1: Create SignalPreferences**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/prefs/SignalPreferences.kt
package dev.aiaerial.signal.data.prefs

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SignalPreferences @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("signal_prefs", Context.MODE_PRIVATE)

    var openClawUrl: String
        get() = prefs.getString("openclaw_url", "http://127.0.0.1:18789") ?: "http://127.0.0.1:18789"
        set(value) = prefs.edit().putString("openclaw_url", value).apply()

    var syslogPort: Int
        get() = prefs.getInt("syslog_port", 1514)
        set(value) = prefs.edit().putInt("syslog_port", value).apply()

    var setupComplete: Boolean
        get() = prefs.getBoolean("setup_complete", false)
        set(value) = prefs.edit().putBoolean("setup_complete", value).apply()
}
```

**Step 2: Create SettingsViewModel**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/settings/SettingsViewModel.kt
package dev.aiaerial.signal.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import dev.aiaerial.signal.data.openclaw.OpenClawClient
import dev.aiaerial.signal.data.openclaw.OpenClawStatus
import dev.aiaerial.signal.data.prefs.SignalPreferences
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val prefs: SignalPreferences,
    private val openClawClient: OpenClawClient,
) : ViewModel() {

    private val _openClawStatus = MutableStateFlow(OpenClawStatus.CHECKING)
    val openClawStatus: StateFlow<OpenClawStatus> = _openClawStatus.asStateFlow()

    private val _openClawUrl = MutableStateFlow(prefs.openClawUrl)
    val openClawUrl: StateFlow<String> = _openClawUrl.asStateFlow()

    private val _syslogPort = MutableStateFlow(prefs.syslogPort)
    val syslogPort: StateFlow<Int> = _syslogPort.asStateFlow()

    init {
        checkOpenClawHealth()
    }

    fun checkOpenClawHealth() {
        viewModelScope.launch {
            _openClawStatus.value = OpenClawStatus.CHECKING
            _openClawStatus.value = openClawClient.healthCheck()
        }
    }

    fun setOpenClawUrl(url: String) {
        _openClawUrl.value = url
        prefs.openClawUrl = url
        openClawClient.setBaseUrl(url)
        checkOpenClawHealth()
    }

    fun setSyslogPort(port: Int) {
        _syslogPort.value = port
        prefs.syslogPort = port
    }

    fun markSetupComplete() {
        prefs.setupComplete = true
    }
}
```

**Step 3: Create SettingsScreen**

```kotlin
// app/src/main/java/dev/aiaerial/signal/ui/settings/SettingsScreen.kt
package dev.aiaerial.signal.ui.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import dev.aiaerial.signal.data.openclaw.OpenClawStatus

@Composable
fun SettingsScreen(viewModel: SettingsViewModel = hiltViewModel()) {
    val openClawStatus by viewModel.openClawStatus.collectAsState()
    val openClawUrl by viewModel.openClawUrl.collectAsState()
    val syslogPort by viewModel.syslogPort.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
    ) {
        // OpenClaw Connection
        Text("OpenClaw Connection", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Status")
                    val (statusText, statusColor) = when (openClawStatus) {
                        OpenClawStatus.CONNECTED -> "Connected" to MaterialTheme.colorScheme.primary
                        OpenClawStatus.DISCONNECTED -> "Disconnected" to MaterialTheme.colorScheme.error
                        OpenClawStatus.CHECKING -> "Checking..." to MaterialTheme.colorScheme.onSurfaceVariant
                    }
                    Text(statusText, color = statusColor)
                }

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = openClawUrl,
                    onValueChange = { viewModel.setOpenClawUrl(it) },
                    label = { Text("Gateway URL") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )

                Spacer(modifier = Modifier.height(8.dp))

                Button(onClick = { viewModel.checkOpenClawHealth() }) {
                    Text("Test Connection")
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Syslog Settings
        Text("Syslog Receiver", style = MaterialTheme.typography.titleMedium)
        Spacer(modifier = Modifier.height(8.dp))

        Card(modifier = Modifier.fillMaxWidth()) {
            Column(modifier = Modifier.padding(16.dp)) {
                OutlinedTextField(
                    value = syslogPort.toString(),
                    onValueChange = { it.toIntOrNull()?.let { p -> viewModel.setSyslogPort(p) } },
                    label = { Text("UDP Port") },
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                )
                Text(
                    "Configure your WLC to send syslog to this device's IP on this port.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Setup guide
        if (openClawStatus == OpenClawStatus.DISCONNECTED) {
            Text("Setup Guide", style = MaterialTheme.typography.titleMedium)
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        "OpenClaw is not running. To enable AI features:",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("1. Install Termux from F-Droid")
                    Text("2. In Termux, run: pkg install nodejs-lts")
                    Text("3. Run: npx openclaw@latest init")
                    Text("4. Run: npx openclaw gateway start")
                    Text("5. Come back here and tap 'Test Connection'")
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        "Full guide: github.com/bgorzelic/openclaw-android-edge",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // App info
        Text("About", style = MaterialTheme.typography.titleMedium)
        Text("SIGNAL v0.1.0", style = MaterialTheme.typography.bodySmall)
        Text("AI Aerial Solutions", style = MaterialTheme.typography.bodySmall)
    }
}
```

**Step 4: Wire into navigation**

```kotlin
composable(SignalScreen.Settings.route) {
    SettingsScreen()
}
```

**Step 5: Build and commit**

```bash
git add -A
git commit -m "feat: add settings screen with OpenClaw setup wizard and connection health"
```

---

## Task 11: Basic Export / Reporting

**Goal:** Export current session events as JSON or CSV for sharing.

**Files:**
- Create: `app/src/main/java/dev/aiaerial/signal/data/export/SessionExporter.kt`
- Test: `app/src/test/java/dev/aiaerial/signal/data/export/SessionExporterTest.kt`

**Step 1: Write failing test**

```kotlin
// app/src/test/java/dev/aiaerial/signal/data/export/SessionExporterTest.kt
package dev.aiaerial.signal.data.export

import dev.aiaerial.signal.data.model.EventType
import dev.aiaerial.signal.data.model.NetworkEvent
import dev.aiaerial.signal.data.model.Vendor
import org.junit.Assert.*
import org.junit.Test

class SessionExporterTest {

    @Test
    fun `export events as CSV`() {
        val events = listOf(
            NetworkEvent(
                id = 1, timestamp = 1710000000000L, eventType = EventType.ROAM,
                clientMac = "aa:bb:cc:dd:ee:ff", apName = "AP-1", channel = 36,
                rssi = -65, vendor = Vendor.CISCO, rawMessage = "raw1", sessionId = "s1"
            ),
            NetworkEvent(
                id = 2, timestamp = 1710000001000L, eventType = EventType.DEAUTH,
                clientMac = "aa:bb:cc:dd:ee:ff", apName = "AP-2", reasonCode = 8,
                vendor = Vendor.CISCO, rawMessage = "raw2", sessionId = "s1"
            ),
        )
        val csv = SessionExporter.toCsv(events)
        assertTrue(csv.startsWith("timestamp,event_type,client_mac,ap_name,bssid,channel,rssi,reason_code,vendor"))
        assertTrue(csv.contains("ROAM,aa:bb:cc:dd:ee:ff,AP-1"))
        assertTrue(csv.contains("DEAUTH,aa:bb:cc:dd:ee:ff,AP-2"))
        assertEquals(3, csv.lines().size) // header + 2 events
    }

    @Test
    fun `export events as JSON`() {
        val events = listOf(
            NetworkEvent(
                id = 1, timestamp = 1710000000000L, eventType = EventType.ROAM,
                clientMac = "aa:bb:cc:dd:ee:ff", apName = "AP-1",
                vendor = Vendor.CISCO, rawMessage = "raw1", sessionId = "s1"
            ),
        )
        val json = SessionExporter.toJson(events)
        assertTrue(json.contains("\"eventType\":\"ROAM\""))
        assertTrue(json.contains("\"clientMac\":\"aa:bb:cc:dd:ee:ff\""))
    }
}
```

**Step 2: Implement SessionExporter**

```kotlin
// app/src/main/java/dev/aiaerial/signal/data/export/SessionExporter.kt
package dev.aiaerial.signal.data.export

import dev.aiaerial.signal.data.model.NetworkEvent
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

object SessionExporter {

    private val json = Json { prettyPrint = true }

    fun toCsv(events: List<NetworkEvent>): String = buildString {
        appendLine("timestamp,event_type,client_mac,ap_name,bssid,channel,rssi,reason_code,vendor")
        events.forEach { e ->
            appendLine(
                "${e.timestamp},${e.eventType},${e.clientMac ?: ""},${e.apName ?: ""}," +
                "${e.bssid ?: ""},${e.channel ?: ""},${e.rssi ?: ""},${e.reasonCode ?: ""},${e.vendor}"
            )
        }
    }.trimEnd()

    fun toJson(events: List<NetworkEvent>): String {
        val serializable = events.map { e ->
            mapOf(
                "timestamp" to e.timestamp.toString(),
                "eventType" to e.eventType.name,
                "clientMac" to (e.clientMac ?: ""),
                "apName" to (e.apName ?: ""),
                "bssid" to (e.bssid ?: ""),
                "channel" to (e.channel?.toString() ?: ""),
                "rssi" to (e.rssi?.toString() ?: ""),
                "reasonCode" to (e.reasonCode?.toString() ?: ""),
                "vendor" to e.vendor.name,
                "rawMessage" to e.rawMessage,
            )
        }
        return json.encodeToString(serializable)
    }
}
```

**Step 3: Run tests**

Run: `./gradlew test --tests "dev.aiaerial.signal.data.export.SessionExporterTest"`
Expected: PASS

**Step 4: Add export button to SyslogScreen** — Share intent with CSV/JSON attachment.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add session export as CSV and JSON"
```

---

## Task 12: Create GitHub Repo and Push

**Goal:** Initialize the SIGNAL repo on GitHub and push the initial codebase.

**Step 1: Create repo**

```bash
gh repo create bgorzelic/signal-app --public --description "SIGNAL — Wireless network engineer's companion. Edge AI diagnostics powered by OpenClaw." --clone=false
```

**Step 2: Add remote and push**

```bash
cd signal-app
git remote add origin https://github.com/bgorzelic/signal-app.git
git push -u origin main
```

**Step 3: Update ACTIVE_PROJECTS.md**

Add SIGNAL entry with v0.1.0-dev status.

---

## Summary

| Task | Feature | Key Files |
|---|---|---|
| 1 | Project scaffolding | build.gradle.kts, Navigation, Hilt |
| 2 | Data models + Room DB | NetworkEvent, DAO, Database |
| 3 | WiFi Scanner | WifiScanner, ScannerScreen |
| 4 | Syslog Receiver | UDP listener, Foreground service |
| 5 | Cisco WLC Parser | CiscoWlcParser, VendorDetector |
| 6 | Parser-Syslog integration | EventPipeline |
| 7 | Roaming Timeline | TimelineScreen, journey viz |
| 8 | OpenClaw AI Triage | OpenClawClient, TriageBottomSheet |
| 9 | Log File Import | LogImportScreen, AI analysis |
| 10 | Settings + Setup Wizard | SettingsScreen, health check |
| 11 | Export / Reporting | SessionExporter (CSV/JSON) |
| 12 | GitHub repo + push | Repo creation, ACTIVE_PROJECTS |

**Estimated test coverage:** Core parsers and data models at ~80%+. UI tested manually on device.

**After completing all tasks:** Run full test suite with `./gradlew test`, install on Pixel 10a, verify syslog reception from a test WLC or `nc -u` command.
