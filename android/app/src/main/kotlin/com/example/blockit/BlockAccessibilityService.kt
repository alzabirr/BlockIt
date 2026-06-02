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

class BlockAccessibilityService : AccessibilityService() {

    private val sessionScrollCount = HashMap<String, Int>()
    private var lastPackageName: String? = null

    // Track the current foreground Activity/Fragment class name per package
    // This is set on TYPE_WINDOW_STATE_CHANGED events which fire when a new screen opens
    private val currentClassName = HashMap<String, String>()

    // Known Shorts/Reels activity and fragment class names for each app
    // These are the fullscreen video player screens — NOT the navigation tab labels
    private val shortsReelsClasses = mapOf(
        "com.google.android.youtube" to setOf(
            "com.google.android.apps.youtube.app.watchwhile.WatchWhileActivity",
            "com.google.android.youtube.ui.shorts.ShortsActivity",
            "com.google.android.apps.youtube.shorts.shorts.ShortsActivity",
            "com.google.android.apps.youtube.app.shorts.ShortsActivity",
            // fragment-level (class name contains these)
            "shorts"
        ),
        "com.instagram.android" to setOf(
            "com.instagram.mainactivity.InstagramMainActivity", // handled by class name check
            "com.instagram.reel.activity.ReelViewerActivity",
            "com.instagram.clips.activity.ClipsViewerActivity",
            // fragment-level (class name contains these)
            "reel", "clips"
        ),
        "com.facebook.katana" to setOf(
            "com.facebook.reels.player.ReelPlayerActivity",
            "com.facebook.reels.ReelsActivity",
            // fragment-level (class name contains these)
            "reel", "shortvideo"
        )
    )

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val packageName = event.packageName?.toString() ?: return

        // Do not monitor our own app
        if (packageName == applicationContext.packageName) return

        val limits = getAppLimits()
        val config = limits[packageName] ?: return

        // Track window/activity changes to know which screen the user is on
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val className = event.className?.toString() ?: ""
            if (className.isNotEmpty()) {
                currentClassName[packageName] = className
                android.util.Log.d("BlockIt", "Window changed: pkg=$packageName class=$className")
            }

            // Reset scroll count when screen changes within an app
            if (packageName != lastPackageName) {
                sessionScrollCount.clear()
                lastPackageName = packageName
            }
        }

        // 1. Block Entire App — trigger on every event when blocked
        if (config.isBlocked && config.blockingMode == "all") {
            triggerBlockAction(config.actionType, "App limit reached! Blocked for today.")
            return
        }

        // 2. Shorts & Reels Only — only block when the user is actually inside the Shorts/Reels player
        val isInShortsReels = isUserInShortsOrReels(packageName)
        android.util.Log.d("BlockIt", "pkg=$packageName isInShortsReels=$isInShortsReels blocked=${config.isBlocked} mode=${config.blockingMode}")

        if (isInShortsReels) {
            if (config.isBlocked && config.blockingMode == "shorts_reels") {
                triggerBlockAction(config.actionType, "Time's up! Shorts & Reels blocked for today.")
                return
            }

            // Curious Mode: limit number of scroll actions within the Shorts/Reels player
            if (config.isCuriousMode && event.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED) {
                val currentScrolls = sessionScrollCount[packageName] ?: 0
                val nextScrolls = currentScrolls + 1
                sessionScrollCount[packageName] = nextScrolls

                if (nextScrolls >= config.maxScrolls) {
                    triggerBlockAction(
                        config.actionType,
                        "Curious Mode: ${config.maxScrolls} scrolls reached!"
                    )
                }
            }
        } else {
            // User left Shorts/Reels player — reset scroll counter
            if (sessionScrollCount.containsKey(packageName)) {
                sessionScrollCount.remove(packageName)
            }
        }
    }

    /**
     * Checks whether the user is currently inside a Shorts/Reels fullscreen player.
     * Uses the Activity/Fragment class name captured from window state change events.
     * This is far more reliable than scanning all view nodes in the hierarchy.
     */
    private fun isUserInShortsOrReels(packageName: String): Boolean {
        val className = currentClassName[packageName]?.lowercase() ?: return false
        val knownClasses = shortsReelsClasses[packageName] ?: return false

        for (known in knownClasses) {
            if (className.contains(known.lowercase())) {
                android.util.Log.d("BlockIt", "ShortsReels match: class=$className matches=$known")
                return true
            }
        }
        return false
    }

    override fun onInterrupt() {
        // Required method
    }

    private fun triggerBlockAction(actionType: String, message: String) {
        android.util.Log.d("BlockIt", "Triggering block action: $actionType")
        when (actionType) {
            "close_player" -> {
                // Press back twice — exits fullscreen player back to the app feed
                performGlobalAction(GLOBAL_ACTION_BACK)
                Handler(Looper.getMainLooper()).postDelayed({
                    performGlobalAction(GLOBAL_ACTION_BACK)
                }, 150)
            }
            "exit_app" -> {
                performGlobalAction(GLOBAL_ACTION_HOME)
            }
            "lock_screen" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
                }
                // Also go home so app isn't in foreground after unlock
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
