package com.example.blockit

import android.accessibilityservice.AccessibilityService
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import org.json.JSONArray
import java.util.Calendar

class BlockAccessibilityService : AccessibilityService() {
    private val handler = Handler(Looper.getMainLooper())
    private var currentForegroundPackage: String? = null

    private val checkRunnable = object : Runnable {
        override fun run() {
            val pkg = currentForegroundPackage
            if (pkg != null) {
                val config = getAppLimits()[pkg]
                if (config != null) {
                    val usageMs = getUsageStatsForPackage(pkg)
                    val usedMins = (usageMs / 1000 / 60).toInt()
                    if (usedMins >= config.limitMinutes || config.isBlocked) {
                        if (!config.isBlocked) {
                            updateAppLimitBlockedState(pkg, true)
                        }
                        triggerBlockAction(config.actionType, "App limit reached! Blocked for today.")
                    } else {
                        // Reschedule verification check in 3 seconds
                        handler.postDelayed(this, 3000)
                    }
                }
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == applicationContext.packageName) return

        // Update active package on window state changes
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val previousPackage = currentForegroundPackage
            currentForegroundPackage = packageName

            if (previousPackage != packageName) {
                // Stop any existing runnable first
                handler.removeCallbacks(checkRunnable)

                val config = getAppLimits()[packageName]
                if (config != null) {
                    val usageMs = getUsageStatsForPackage(packageName)
                    val usedMins = (usageMs / 1000 / 60).toInt()
                    if (usedMins >= config.limitMinutes || config.isBlocked) {
                        if (!config.isBlocked) {
                            updateAppLimitBlockedState(packageName, true)
                        }
                        triggerBlockAction(config.actionType, "App limit reached! Blocked for today.")
                    } else {
                        // Start the periodic monitoring
                        handler.postDelayed(checkRunnable, 3000)
                    }
                }
            }
        }
    }

    override fun onInterrupt() {
        handler.removeCallbacks(checkRunnable)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(checkRunnable)
    }

    private fun triggerBlockAction(actionType: String, message: String) {
        when (actionType) {
            "lock_screen" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
                }
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            else -> {
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
        }

        Handler(Looper.getMainLooper()).post {
            Toast.makeText(applicationContext, message, Toast.LENGTH_LONG).show()
        }
    }

    private fun getUsageStatsForPackage(packageName: String): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager ?: return 0L
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis

        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis

        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: return 0L

        var totalTime = 0L
        for (stats in usageStats) {
            if (stats.packageName == packageName) {
                totalTime += stats.totalTimeInForeground
            }
        }
        return totalTime
    }

    private fun updateAppLimitBlockedState(packageName: String, isBlocked: Boolean) {
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val key = if (prefs.contains("flutter.app_limits")) "flutter.app_limits" else "app_limits"
        val limitsJson = prefs.getString(key, null) ?: return

        try {
            val jsonArray = JSONArray(limitsJson)
            var modified = false
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                if (obj.getString("packageName") == packageName) {
                    obj.put("isBlocked", isBlocked)
                    modified = true
                }
            }
            if (modified) {
                prefs.edit().putString(key, jsonArray.toString()).apply()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getAppLimits(): Map<String, AppLimitConfig> {
        val limitsMap = HashMap<String, AppLimitConfig>()
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val limitsJson = prefs.getString("flutter.app_limits", null)
            ?: prefs.getString("app_limits", null)
            ?: return limitsMap

        try {
            val jsonArray = JSONArray(limitsJson)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val packageName = obj.getString("packageName")
                val isBlocked = obj.optBoolean("isBlocked", false)
                val actionType = obj.optString("actionType", "exit_app")
                val limitMinutes = obj.optInt("limitMinutes", 0)

                limitsMap[packageName] = AppLimitConfig(packageName, isBlocked, actionType, limitMinutes)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return limitsMap
    }
}

data class AppLimitConfig(
    val packageName: String,
    val isBlocked: Boolean,
    val actionType: String,
    val limitMinutes: Int
)
