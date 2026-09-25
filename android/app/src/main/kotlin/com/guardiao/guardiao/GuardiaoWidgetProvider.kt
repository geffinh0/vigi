package com.guardiao.guardiao

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class GuardiaoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.guardiao_widget_layout)
            val widgetData = HomeWidgetPlugin.getData(context)
            val vigiState = widgetData.getString("vigi_state", "normal") ?: "normal"
            val isMonitoring = widgetData.getBoolean("is_monitoring", false)
            val modeName = widgetData.getString("mode_name", "Rotina padrão") ?: "Rotina padrão"
            val timeDisplay = widgetData.getString("time_display", "") ?: ""
            val statusDisplay = widgetData.getString("status_display", "") ?: ""

            val finalStatus = if (statusDisplay.isNotEmpty()) {
                statusDisplay
            } else if (isMonitoring) {
                modeName
            } else {
                "VIGI"
            }

            val finalTime = if (timeDisplay.isNotEmpty()) {
                timeDisplay
            } else if (isMonitoring) {
                "60 min"
            } else {
                "Pausado"
            }

            views.setTextViewText(R.id.widget_status, finalStatus)
            views.setTextViewText(R.id.widget_time, finalTime)

            when (vigiState.lowercase()) {
                "alerta" -> views.setImageViewResource(R.id.widget_icon, R.drawable.ic_vigi_alerta)
                "atento" -> views.setImageViewResource(R.id.widget_icon, R.drawable.ic_vigi_atento)
                else -> views.setImageViewResource(R.id.widget_icon, R.drawable.ic_vigi_normal)
            }

            // 1. Botão Principal "Estou bem" (RequestCode: 1001)
            views.setOnClickPendingIntent(
                R.id.widget_button,
                createPendingIntent(context, 1001, "guardiao://confirmar_checkin")
            )

            // 2. Botão Rápido "Banho" (RequestCode: 1002)
            views.setOnClickPendingIntent(
                R.id.widget_btn_banho,
                createPendingIntent(context, 1002, "guardiao://iniciar_banho")
            )

            // 3. Botão Rápido "Sono" (RequestCode: 1003)
            views.setOnClickPendingIntent(
                R.id.widget_btn_sono,
                createPendingIntent(context, 1003, "guardiao://iniciar_sono")
            )

            // 4. Botão de Emergência "SOS / Pânico" (RequestCode: 1004)
            views.setOnClickPendingIntent(
                R.id.widget_btn_sos,
                createPendingIntent(context, 1004, "guardiao://disparar_panico")
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /// Os botões abrem o app com a ação (LAUNCH) em vez de rodar num isolate de
    /// background: lá o Supabase não é inicializado e o cronômetro/alarme do app
    /// não ficaria sabendo do check-in, gerando alerta falso aos contatos.
    private fun createPendingIntent(
        context: Context,
        requestCode: Int,
        uriString: String
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse(uriString)
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }
        val flags = if (Build.VERSION.SDK_INT >= 23) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }
}
