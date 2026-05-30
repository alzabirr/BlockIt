package com.example.blockit

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.view.accessibility.AccessibilityEvent
import android.widget.Toast
import android.os.Handler
import android.os.Looper

class BlockAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            // Do not block our own app
            if (packageName == applicationContext.packageName) return

            // Load blocked packages
            val blocked = getBlockedPackages()
            if (blocked.contains(packageName)) {
                // Perform global home action to block the app
                performGlobalAction(GLOBAL_ACTION_HOME)
                
                // Show a Toast message on the main thread
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(
                        applicationContext,
                        "Time's up! This app is blocked for today.",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }

    override fun onInterrupt() {
        // Required method
    }

    private fun getBlockedPackages(): Set<String> {
        val prefs = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Try reading "flutter.blocked_packages"
        var blocked = prefs.getStringSet("flutter.blocked_packages", null)
        if (blocked != null) return blocked
        
        // Try reading "blocked_packages"
        blocked = prefs.getStringSet("blocked_packages", null)
        if (blocked != null) return blocked

        // Try default preferences
        val defaultPrefs = applicationContext.getSharedPreferences(
            "${applicationContext.packageName}_preferences",
            Context.MODE_PRIVATE
        )
        blocked = defaultPrefs.getStringSet("blocked_packages", null)
        if (blocked != null) return blocked

        return emptySet()
    }
}
