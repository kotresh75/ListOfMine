package com.listofmine.listofmine

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ListAppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data saved from Flutter
                val moviesStat = widgetData.getString("movies_stat", "🎬 0 / 0")
                val placesStat = widgetData.getString("places_stat", "✈️ 0 / 0")
                val latestItem = widgetData.getString("latest_item", "No items added yet")
                val latestCategory = widgetData.getString("latest_category", "Upcoming")

                setTextViewText(R.id.widget_movies_stat, moviesStat)
                setTextViewText(R.id.widget_places_stat, placesStat)
                setTextViewText(R.id.widget_latest_item, latestItem)
                setTextViewText(R.id.widget_latest_label, latestCategory)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
