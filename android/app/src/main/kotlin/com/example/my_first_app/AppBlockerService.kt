package com.unloop.app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray

class AppBlockerService : AccessibilityService() {
    private var lastRedirectAt = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        refreshState(applicationContext)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val preferences = getSharedPreferences("unloop_blocker", Context.MODE_PRIVATE)
        if (!preferences.getBoolean("blocker_enabled", false)) return
        val appPackage = event.packageName?.toString() ?: return
        if (appPackage == packageName) return
        val packages = runCatching {
            JSONArray(preferences.getString("blocker_packages", "[]"))
                .let { array -> List(array.length()) { index -> array.optString(index) } }
        }.getOrDefault(emptyList())
        if (!packages.contains(appPackage)) return
        val now = System.currentTimeMillis()
        if (now - lastRedirectAt < 1500L) return
        lastRedirectAt = now

        val appName = runCatching {
            packageManager.getApplicationLabel(
                packageManager.getApplicationInfo(appPackage, 0),
            ).toString()
        }.getOrDefault(appPackage)
        preferences.edit()
            .putString("pending_package", appPackage)
            .putString("pending_name", appName)
            .apply()

        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.unloop.app.BLOCKER_REDIRECT"
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        startActivity(intent)
    }

    override fun onInterrupt() = Unit

    companion object {
        fun refreshState(context: Context) {
            // Reads the same shared preferences written by the Flutter bridge.
            // Keeping this static makes the state visible as soon as the service
            // starts, including after an operating-system process restart.
            context.getSharedPreferences("unloop_blocker", Context.MODE_PRIVATE)
                .getBoolean("packages_dirty", false)
        }
    }
}
