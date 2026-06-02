package com.example.blockit

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import org.json.JSONArray

class BlockAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == applicationContext.packageName) return

        val config = getAppLimits()[packageName] ?: return
        if (config.isBlocked) {
            triggerBlockAction(config.actionType, "App limit reached! Blocked for today.")
        }
    }

    override fun onInterrupt() {
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

                limitsMap[packageName] = AppLimitConfig(packageName, isBlocked, actionType)
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
    val actionType: String
)
