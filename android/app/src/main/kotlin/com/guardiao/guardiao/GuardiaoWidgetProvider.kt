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
                    val minutesRemaining = widgetData.getInt("minutes_remaining", 60)
                    val isMonitoring = widgetData.getBoolean("is_monitoring", false)
                    val modeName = widgetData.getString("mode_name", "Rotina padrão") ?: "Rotina padrão"

                    if (isMonitoring) {
                        setTextViewText(R.id.widget_status, modeName)
                        setTextViewText(R.id.widget_time, "$minutesRemaining min")
                    } else {
                        setTextViewText(R.id.widget_status, "Guardião")
                        setTextViewText(R.id.widget_time, "Pausado")
                    }

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
