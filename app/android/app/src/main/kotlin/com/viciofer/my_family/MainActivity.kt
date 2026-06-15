package com.viciofer.my_family

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BackgroundLocationService.CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val token = call.argument<String>("token")
                        val apiBaseUrl = call.argument<String>("apiBaseUrl")
                        if (token.isNullOrBlank() || apiBaseUrl.isNullOrBlank()) {
                            result.error("invalid_args", "Token e API base são obrigatórios.", null)
                            return@setMethodCallHandler
                        }
                        BackgroundLocationService.saveConfig(this, token, apiBaseUrl)
                        val intent = Intent(this, BackgroundLocationService::class.java)
                            .setAction(BackgroundLocationService.ACTION_START)
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                        } catch (error: Throwable) {
                            BackgroundLocationService.clearConfig(this)
                            result.error(
                                "start_failed",
                                error.message ?: "Não foi possível iniciar a localização.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        result.success(true)
                    }
                    "stop" -> {
                        BackgroundLocationService.clearConfig(this)
                        val intent = Intent(this, BackgroundLocationService::class.java)
                            .setAction(BackgroundLocationService.ACTION_STOP)
                        startService(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
