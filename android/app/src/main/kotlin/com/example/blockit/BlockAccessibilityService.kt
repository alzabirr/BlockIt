package com.example.blockit

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast
import android.os.Handler
import android.os.Looper
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

class BlockAccessibilityService : AccessibilityService() {

    private val sessionScrollCount = HashMap<String, Int>()
    private var lastPackageName: String? = null

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return

        // Reset scroll counter if we switch apps
        if (packageName != lastPackageName) {
            sessionScrollCount.clear()
            lastPackageName = packageName
        }

        // Do not block our own app
        if (packageName == applicationContext.packageName) return

        val limits = getAppLimits()
        val config = limits[packageName] ?: return

        // 1. If the app is set to "Block All" and is blocked (limit reached)
        if (config.isBlocked && config.blockingMode == "all") {
            triggerBlockAction(config.actionType, "App limit reached! This app is blocked for today.")
            return
        }

        // 2. Shorts & Reels Detection
        val rootNode = rootInActiveWindow
        val isShortsActive = isShortsOrReelsNode(rootNode, packageName)

        if (isShortsActive) {
            // Check if blocked because limit is reached (and blocking mode is shorts_reels)
            if (config.isBlocked && config.blockingMode == "shorts_reels") {
                triggerBlockAction(config.actionType, "Time's up! Shorts & Reels are blocked for today.")
                return
            }

            // If Curious Mode is enabled, handle scroll events
            if (config.isCuriousMode) {
                if (event.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
                    val currentScrolls = sessionScrollCount[packageName] ?: 0
                    val nextScrolls = currentScrolls + 1
                    sessionScrollCount[packageName] = nextScrolls

                    if (nextScrolls >= config.maxScrolls) {
                        triggerBlockAction(
                            config.actionType, 
                            "Curious Mode limit reached! (${config.maxScrolls} scrolls max)"
                        )
                    }
                }
            } else if (config.blockingMode == "shorts_reels") {
                // If not curious mode, and blockingMode is shorts_reels, block immediately
                triggerBlockAction(config.actionType, "Shorts & Reels are blocked!")
            }
        }
    }

    override fun onInterrupt() {
        // Required method
    }

    private fun isShortsOrReelsNode(node: AccessibilityNodeInfo?, packageName: String): Boolean {
        if (node == null) return false

        val id = node.viewIdResourceName?.lowercase() ?: ""
        val text = node.text?.toString()?.lowercase() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase() ?: ""

        // Package specific detection logic
        when (packageName) {
            "com.google.android.youtube" -> {
                if (id.contains("shorts") || id.contains("reel") || 
                    text.contains("shorts") || desc.contains("shorts")) {
                    return true
                }
            }
            "com.instagram.android" -> {
                if (id.contains("reel") || id.contains("clips") || 
                    text.contains("reels") || desc.contains("reels")) {
                    return true
                }
            }
            "com.facebook.katana" -> {
                if (id.contains("reel") || id.contains("short_video") || 
                    text.contains("reels") || desc.contains("reels")) {
                    return true
                }
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (isShortsOrReelsNode(child, packageName)) {
                return true
            }
        }
        return false
    }

    private fun triggerBlockAction(actionType: String, message: String) {
        when (actionType) {
            "close_player" -> {
                performGlobalAction(GLOBAL_ACTION_BACK)
            }
            "exit_app" -> {
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            "lock_screen" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
                } else {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                }
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
                val limitMinutes = obj.getInt("limitMinutes")
                val usedMinutes = obj.optInt("usedMinutes", 0)
                val isBlocked = obj.optBoolean("isBlocked", false)
                val blockingMode = obj.optString("blockingMode", "shorts_reels")
                val isCuriousMode = obj.optBoolean("isCuriousMode", false)
                val maxScrolls = obj.optInt("maxScrolls", 3)
                val actionType = obj.optString("actionType", "close_player")

                limitsMap[packageName] = AppLimitConfig(
                    packageName, limitMinutes, usedMinutes, isBlocked,
                    blockingMode, isCuriousMode, maxScrolls, actionType
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return limitsMap
    }
}

data class AppLimitConfig(
    val packageName: String,
    val limitMinutes: Int,
    val usedMinutes: Int,
    val isBlocked: Boolean,
    val blockingMode: String,
    val isCuriousMode: Boolean,
    val maxScrolls: Int,
    val actionType: String
)
