package com.guardiao.guardiao

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Canal nativo de SMS de emergência: envia a mensagem diretamente pela operadora,
/// sem depender de internet e sem exigir que o usuário toque em "enviar".
class MainActivity : FlutterActivity() {
    private val channelName = "guardiao/emergency_sms"
    private val smsPermissionRequestCode = 4711

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasSmsPermission())
                    "requestPermission" -> {
                        // SMS e localização num único diálogo: pedidos simultâneos
                        // separados fazem o Android descartar um deles.
                        val missing = arrayOf(
                            Manifest.permission.SEND_SMS,
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION,
                        ).filter {
                            ContextCompat.checkSelfPermission(this, it) !=
                                PackageManager.PERMISSION_GRANTED
                        }
                        if (missing.isNotEmpty()) {
                            ActivityCompat.requestPermissions(
                                this,
                                missing.toTypedArray(),
                                smsPermissionRequestCode,
                            )
                        }
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
    }

    private fun hasSmsPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) ==
            PackageManager.PERMISSION_GRANTED

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
