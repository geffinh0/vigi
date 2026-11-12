package com.guardiao.guardiao

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/// Widget da tela inicial do Vigi (Guia de Design, seção 12).
///
/// Mostra a coruja no estado atual e o horário do próximo check-in. Quando é
/// a vez da pessoa, o widget inteiro vira um botão âmbar de toque único
/// ("Estou bem"). Cada degrau da escada de estados define o fundo, a coruja,
/// os textos e o que o toque faz.
///
/// Não há botão de pânico: pedir ajuda exige segurar por 3 segundos, e um
/// widget só entende toques simples.
class GuardiaoWidgetProvider : AppWidgetProvider() {

    /// Aparência e ação do widget em um degrau da escada.
    private data class Look(
        val background: Int,
        val icon: Int,
        val title: String,
        val subtitle: String,
        val titleColor: Int,
        val subtitleColor: Int,
        val uri: String,
        val requestCode: Int,
    )

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
            val isMonitoring = widgetData.getBoolean("is_monitoring", false)
            val time = widgetData.getString("time_display", "") ?: ""
            val state = normalizeState(
                widgetData.getString("vigi_state", "descansando") ?: "descansando",
                isMonitoring,
            )

            val look = lookFor(context, state, time)

            views.setInt(R.id.widget_container, "setBackgroundResource", look.background)
            views.setImageViewResource(R.id.widget_icon, look.icon)
            views.setTextViewText(R.id.widget_time, look.title)
            views.setTextViewText(R.id.widget_status, look.subtitle)
            views.setTextColor(
                R.id.widget_time,
                ContextCompat.getColor(context, look.titleColor),
            )
            views.setTextColor(
                R.id.widget_status,
                ContextCompat.getColor(context, look.subtitleColor),
            )
            // Para o leitor de tela: "Vigi. 15:00, próximo check-in".
            views.setContentDescription(
                R.id.widget_container,
                "Vigi. ${look.title}, ${look.subtitle}",
            )
            views.setOnClickPendingIntent(
                R.id.widget_container,
                createPendingIntent(context, look.requestCode, look.uri),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /// Versões anteriores do app gravavam "normal", "atento" e "alerta".
    private fun normalizeState(raw: String, isMonitoring: Boolean): String =
        when (raw) {
            "descansando", "vigiando", "noturno", "suaVez", "ultimaChamada", "alerta" -> raw
            "aliviado" -> "vigiando"
            else -> if (isMonitoring) "vigiando" else "descansando"
        }

    private fun lookFor(context: Context, state: String, time: String): Look {
        val open = context.getString(R.string.widget_open_subtitle)
        // Sem horário (dado antigo ou ainda não sincronizado), o widget diz
        // só o estado, em vez de repetir o rótulo.
        val watchingTitle = time.ifEmpty {
            context.getString(R.string.widget_watching_title)
        }
        val watchingSubtitle =
            if (time.isEmpty()) open
            else context.getString(R.string.widget_next_checkin)
        return when (state) {
            // É a vez da pessoa: o widget inteiro é o botão "Estou bem".
            "suaVez", "ultimaChamada" -> Look(
                background = R.drawable.widget_background_sua_vez,
                icon = R.drawable.ic_vigi_sua_vez,
                title = context.getString(R.string.widget_your_turn_title),
                subtitle = context.getString(R.string.widget_your_turn_subtitle),
                titleColor = R.color.vigi_petroleo_800,
                subtitleColor = R.color.vigi_petroleo_800,
                uri = "guardiao://confirmar_checkin",
                requestCode = 1001,
            )
            // Contatos avisados: o toque abre o app, onde dá para cancelar.
            "alerta" -> Look(
                background = R.drawable.widget_background_alerta,
                icon = R.drawable.ic_vigi_alerta,
                title = context.getString(R.string.widget_alert_title),
                subtitle = open,
                titleColor = R.color.vigi_branco,
                subtitleColor = R.color.vigi_branco,
                uri = "guardiao://abrir",
                requestCode = 1005,
            )
            "noturno" -> Look(
                background = R.drawable.widget_background_noturno,
                icon = R.drawable.ic_vigi_noturno,
                title = watchingTitle,
                subtitle = watchingSubtitle,
                titleColor = R.color.vigi_linho_100,
                subtitleColor = R.color.vigi_petroleo_300,
                uri = "guardiao://abrir",
                requestCode = 1005,
            )
            "vigiando" -> Look(
                background = R.drawable.widget_background,
                icon = R.drawable.ic_vigi_vigiando,
                title = watchingTitle,
                subtitle = watchingSubtitle,
                titleColor = R.color.vigi_petroleo_800,
                subtitleColor = R.color.vigi_cinza_texto,
                uri = "guardiao://abrir",
                requestCode = 1005,
            )
            // Pausado: a coruja de olhos fechados. O Vigi não finge estar
            // protegendo quando não está.
            else -> Look(
                background = R.drawable.widget_background,
                icon = R.drawable.ic_vigi_descansando,
                title = context.getString(R.string.widget_resting_title),
                subtitle = open,
                titleColor = R.color.vigi_petroleo_800,
                subtitleColor = R.color.vigi_cinza_texto,
                uri = "guardiao://abrir",
                requestCode = 1005,
            )
        }
    }

    /// O toque abre o app com a ação (LAUNCH) em vez de rodar num isolate de
    /// background: lá o Supabase não é inicializado e o cronômetro do app não
    /// ficaria sabendo do check-in, gerando alerta falso aos contatos.
    private fun createPendingIntent(
        context: Context,
        requestCode: Int,
        uriString: String
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            data = Uri.parse(uriString)
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
