package com.twentyone.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class TwentyOneWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val streak = prefs.getString("streak", "0") ?: "0"
        val rimanenti = prefs.getString("rimanenti", "21") ?: "21"

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.widget_streak_value, streak)
            views.setTextViewText(R.id.widget_rimanenti_value, rimanenti)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
