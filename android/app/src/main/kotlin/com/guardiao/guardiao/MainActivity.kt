package com.guardiao.guardiao

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Canais nativos do Vigi:
///
/// - `guardiao/emergency_sms`: envia o SMS de emergência direto pela
///   operadora, sem depender de internet e sem a pessoa tocar em "enviar".
/// - `vigi/system`: consulta e abre as configurações do sistema de que o
///   Vigi depende para vigiar (economia de bateria, alarme em tela cheia).
class MainActivity : FlutterActivity() {
    private val smsChannelName = "guardiao/emergency_sms"
    private val systemChannelName = "vigi/system"
    private val permissionRequestCode = 4711

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasSmsPermission())
                    "requestPermission" -> {
                        // SMS e localização num único diálogo: pedidos simultâneos
                        // separados fazem o Android descartar um deles.
                        requestMissing(
                            Manifest.permission.SEND_SMS,
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION,
                        )
                        result.success(hasSmsPermission())
                    }
                    "requestSmsPermission" -> {
                        // Só o SMS, quando a pessoa toca em "Permitir" nesse item.
                        requestMissing(Manifest.permission.SEND_SMS)
                        result.success(hasSmsPermission())
                    }
                    "send" -> {
                        val phones = call.argument<List<String>>("phones") ?: emptyList()
                        val message = call.argument<String>("message") ?: ""
                        if (!hasSmsPermission()) {
                            result.success(0)
                            return@setMethodCallHandler
                        }
                        result.success(sendSms(phones, message))
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" ->
                        result.success(isIgnoringBatteryOptimizations())
                    "openBatterySettings" -> result.success(
                        openSettings(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    )
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "openFullScreenIntentSettings" -> result.success(openFullScreenIntentSettings())
                    "openAppSettings" -> result.success(
                        openSettings(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            )
                        )
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestMissing(vararg permissions: String) {
        val missing = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                missing.toTypedArray(),
                permissionRequestCode,
            )
        }
    }

    private fun hasSmsPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) ==
            PackageManager.PERMISSION_GRANTED

    /// Com a economia de bateria ligada, o Android pode fechar o Vigi enquanto
    /// ele vigia, e a chamada não toca.
    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            ?: return true
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    /// A partir do Android 14, o alarme em tela cheia (última chamada) depende
    /// de uma autorização que a pessoa pode desligar.
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return true
        return manager.canUseFullScreenIntent()
    }

    private fun openFullScreenIntentSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        return openSettings(
            Intent(
                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                Uri.fromParts("package", packageName, null),
            )
        )
    }

    private fun openSettings(intent: Intent): Boolean =
        try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            // Alguns aparelhos não têm a tela pedida: abre os detalhes do app.
            try {
                startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    )
                )
                true
            } catch (_: Exception) {
                false
            }
        }

    @Suppress("DEPRECATION")
    private fun sendSms(phones: List<String>, message: String): Int {
        val smsManager: SmsManager =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                SmsManager.getDefault()
            }

        var sent = 0
        for (phone in phones) {
            try {
                val parts = smsManager.divideMessage(message)
                smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                sent++
            } catch (_: Exception) {
                // Continua tentando os demais contatos
            }
        }
        return sent
    }
}
