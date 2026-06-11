package com.viciofer.my_family

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.BatteryManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import kotlin.math.min

class BackgroundLocationService : Service() {
    private lateinit var fusedLocation: FusedLocationProviderClient
    private val executor = Executors.newSingleThreadExecutor()
    private var callback: LocationCallback? = null

    override fun onCreate() {
        super.onCreate()
        fusedLocation = LocationServices.getFusedLocationProviderClient(this)
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopTracking()
            else -> startTracking()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        stopLocationUpdates()
        executor.shutdown()
        super.onDestroy()
    }

    private fun startTracking() {
        val config = readConfig(this)
        if (config == null || !hasLocationPermission()) {
            stopSelf()
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION,
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }

        stopLocationUpdates()
        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            UPDATE_INTERVAL_MS,
        )
            .setMinUpdateDistanceMeters(MIN_DISTANCE_METERS)
            .setMinUpdateIntervalMillis(FASTEST_INTERVAL_MS)
            .build()

        callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { sendLocation(config, it) }
            }
        }

        try {
            fusedLocation.requestLocationUpdates(
                request,
                callback as LocationCallback,
                Looper.getMainLooper(),
            )
            fusedLocation.lastLocation.addOnSuccessListener { location ->
                if (location != null) sendLocation(config, location)
            }
        } catch (_: SecurityException) {
            stopTracking()
        }
    }

    private fun stopTracking() {
        stopLocationUpdates()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun stopLocationUpdates() {
        callback?.let { fusedLocation.removeLocationUpdates(it) }
        callback = null
    }

    private fun sendLocation(config: ServiceConfig, location: Location) {
        executor.execute {
            val endpoint = locationUpdateEndpoint(config.apiBaseUrl)
            val body = JSONObject()
                .put("latitude", location.latitude)
                .put("longitude", location.longitude)
                .put("accuracy", location.accuracy.toDouble())
                .put("altitude", location.altitude)
                .put("speed", location.speed.toDouble())
                .put("heading", location.bearing.toDouble())
                .put("platform", "android")
            currentBatteryLevel()?.let { body.put("batteryLevel", it) }
            currentChargingState()?.let { body.put("isCharging", it) }

            var delayMs = 1_000L
            repeat(MAX_SEND_ATTEMPTS) { attempt ->
                if (postLocation(endpoint, config.token, body)) return@execute
                if (attempt < MAX_SEND_ATTEMPTS - 1) {
                    try {
                        Thread.sleep(delayMs)
                    } catch (_: InterruptedException) {
                        return@execute
                    }
                    delayMs = min(delayMs * 2, 8_000L)
                }
            }
        }
    }

    private fun postLocation(endpoint: String, token: String, body: JSONObject): Boolean {
        var connection: HttpURLConnection? = null
        return try {
            connection = (URL(endpoint).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10_000
                readTimeout = 10_000
                doOutput = true
                setRequestProperty("Authorization", "Bearer $token")
                setRequestProperty("Content-Type", "application/json")
            }
            OutputStreamWriter(connection.outputStream).use { writer ->
                writer.write(body.toString())
            }
            val ok = connection.responseCode in 200..299
            val stream = if (ok) connection.inputStream else connection.errorStream
            stream?.use { it.readBytes() }
            ok
        } catch (_: Exception) {
            false
        } finally {
            connection?.disconnect()
        }
    }

    private fun locationUpdateEndpoint(apiBaseUrl: String): String {
        val baseUrl = apiBaseUrl.trim().trimEnd('/')
        return if (baseUrl.endsWith("/api")) {
            "$baseUrl/location/update"
        } else {
            "$baseUrl/api/location/update"
        }
    }

    private fun currentBatteryLevel(): Int? {
        val manager = getSystemService(BATTERY_SERVICE) as? BatteryManager ?: return null
        return manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            .takeIf { it >= 0 }
    }

    private fun currentChargingState(): Boolean? {
        val manager = getSystemService(BATTERY_SERVICE) as? BatteryManager ?: return null
        return when (manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS)) {
            BatteryManager.BATTERY_STATUS_CHARGING,
            BatteryManager.BATTERY_STATUS_FULL -> true
            BatteryManager.BATTERY_STATUS_DISCHARGING,
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> false
            else -> null
        }
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val foreground = fine || coarse
        if (!foreground) return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Localização da família",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Mantém o compartilhamento de localização ativo."
            setShowBadge(false)
        }
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val openIntent = (
            packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java)
            ).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Localização ativa")
            .setContentText("Compartilhando sua localização com a família.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    data class ServiceConfig(val token: String, val apiBaseUrl: String)

    companion object {
        const val CHANNEL = "com.viciofer.my_family/background_location"
        const val ACTION_START = "com.viciofer.my_family.background_location.START"
        const val ACTION_STOP = "com.viciofer.my_family.background_location.STOP"
        private const val PREFS = "background_location"
        private const val KEY_TOKEN = "token"
        private const val KEY_API_BASE_URL = "api_base_url"
        private const val CHANNEL_ID = "my_family_location_tracking"
        private const val NOTIFICATION_ID = 4201
        private const val UPDATE_INTERVAL_MS = 60_000L
        private const val FASTEST_INTERVAL_MS = 30_000L
        private const val MIN_DISTANCE_METERS = 25f
        private const val MAX_SEND_ATTEMPTS = 3

        fun saveConfig(context: Context, token: String, apiBaseUrl: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_TOKEN, token)
                .putString(KEY_API_BASE_URL, apiBaseUrl)
                .apply()
        }

        fun clearConfig(context: Context) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .clear()
                .apply()
        }

        fun readConfig(context: Context): ServiceConfig? {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val token = prefs.getString(KEY_TOKEN, null)?.takeIf { it.isNotBlank() }
            val apiBaseUrl = prefs.getString(KEY_API_BASE_URL, null)?.takeIf { it.isNotBlank() }
            return if (token != null && apiBaseUrl != null) ServiceConfig(token, apiBaseUrl) else null
        }
    }
}
