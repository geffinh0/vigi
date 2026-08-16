package com.guardiao.guardiao

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class GuardiaoWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.guardiao_widget_layout).apply {
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
                        "Guardião"
                    }

                    val finalTime = if (timeDisplay.isNotEmpty()) {
                        timeDisplay
                    } else if (isMonitoring) {
                        "60 min"
                    } else {
                        "Pausado"
                    }

                    setTextViewText(R.id.widget_status, finalStatus)
                    setTextViewText(R.id.widget_time, finalTime)

                    when (vigiState.lowercase()) {
                        "alerta" -> setImageViewResource(R.id.widget_icon, R.drawable.ic_vigi_alerta)
                        "atento" -> setImageViewResource(R.id.widget_icon, R.drawable.ic_vigi_atento)
                        else -> setImageViewResource(R.id.widget_icon, R.drawable.ic_vigi_normal)
                    }

                    // Configura o PendingIntent do botão "Estou bem" para execução em background
                    val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("guardiao://confirmar_checkin")
                    )
                    setOnClickPendingIntent(R.id.widget_button, backgroundIntent)
                }

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
