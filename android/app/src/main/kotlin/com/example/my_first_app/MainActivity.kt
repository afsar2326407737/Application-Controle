package com.unloop.app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.ByteArrayOutputStream
import java.util.Calendar
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val channelName = "com.unloop.app/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    handleMethod(call, result)
                } catch (error: Exception) {
                    result.error("native_error", error.message, null)
                }
            }
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsageAccess" -> result.success(hasUsageAccess())
            "openUsageAccessSettings" -> {
                openSettings(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                result.success(null)
            }
            "openDigitalWellbeingSettings" -> {
                val digitalWellbeingAction = "android.settings.DEVICE_USAGE_SETTINGS"
                val digitalWellbeing = Intent(digitalWellbeingAction)
                if (digitalWellbeing.resolveActivity(packageManager) != null) {
                    openSettings(digitalWellbeingAction)
                } else {
                    openSettings(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                }
                result.success(null)
            }
            "getInstalledApps" -> result.success(getInstalledApps())
            "getUsageForRange" -> {
                val days = call.argument<Int>("days") ?: 7
                result.success(getUsageForRange(days.coerceIn(1, 31)))
            }
            "openApplication" -> {
                val packageName = call.argument<String>("packageName").orEmpty()
                result.success(openApplication(packageName))
            }
            "getBlockerStatus" -> result.success(getBlockerStatus())
            "setBlockerEnabled" -> {
                setBlockerEnabled(call)
                result.success(null)
            }
            "openAccessibilitySettings" -> {
                openSettings(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                result.success(null)
            }
            "consumePendingBlockerEvent" -> result.success(consumePendingBlockerEvent())
            else -> result.notImplemented()
        }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = packageManager.queryIntentActivities(intent, 0)
        val seen = mutableSetOf<String>()
        val result = mutableListOf<Map<String, Any?>>()
        for (activity in activities) {
            val appPackage = activity.activityInfo.packageName
            if (appPackage == packageName || !seen.add(appPackage)) continue
            val label = runCatching {
                activity.loadLabel(packageManager).toString()
            }.getOrDefault(appPackage)
            result.add(
                mapOf(
                    "packageName" to appPackage,
                    "displayName" to label,
                    "icon" to drawableToPng(activity.loadIcon(packageManager)),
                ),
            )
        }
        return result.sortedBy { (it["displayName"] as String).lowercase() }
    }

    private fun drawableToPng(drawable: Drawable): ByteArray? {
        return runCatching {
            val size = 84
            val bitmap = if (drawable is AdaptiveIconDrawable) {
                Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also { target ->
                    val canvas = Canvas(target)
                    drawable.setBounds(0, 0, size, size)
                    drawable.draw(canvas)
                }
            } else {
                Bitmap.createBitmap(
                    max(1, drawable.intrinsicWidth),
                    max(1, drawable.intrinsicHeight),
                    Bitmap.Config.ARGB_8888,
                ).also { target ->
                    val canvas = Canvas(target)
                    drawable.setBounds(0, 0, target.width, target.height)
                    drawable.draw(canvas)
                }
            }
            ByteArrayOutputStream().use { stream ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
                bitmap.recycle()
                stream.toByteArray()
            }
        }.getOrNull()
    }

    private fun getUsageForRange(days: Int): List<Map<String, Any?>> {
        if (!hasUsageAccess()) return emptyList()
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val result = mutableListOf<Map<String, Any?>>()
        val today = Calendar.getInstance()
        today.set(Calendar.HOUR_OF_DAY, 0)
        today.set(Calendar.MINUTE, 0)
        today.set(Calendar.SECOND, 0)
        today.set(Calendar.MILLISECOND, 0)
        val rangeStart = (today.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, -(days - 1))
        }
        val rangeEnd = (today.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, 1)
        }

        for (dayOffset in 0 until days) {
            val dayStart = (rangeStart.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, dayOffset)
            }
            val dayEnd = (dayStart.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, 1)
            }
            val queryEnd = min(dayEnd.timeInMillis, System.currentTimeMillis())
            if (queryEnd <= dayStart.timeInMillis) continue

            val stats = manager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                dayStart.timeInMillis,
                queryEnd,
            )

            // A UsageStats bucket can be created the first time an app becomes
            // visible and updated again on every later foreground transition.
            // firstTimeStamp/lastTimeStamp therefore include background gaps and
            // must never be treated as foreground duration. Android already
            // provides the accumulated foreground total for the daily bucket.
            val foregroundByPackage = stats
                .asSequence()
                .mapNotNull { usage ->
                    val appPackage = usage.packageName ?: return@mapNotNull null
                    if (appPackage == packageName) return@mapNotNull null
                    val foreground = usage.totalTimeInForeground
                        .coerceAtLeast(0L)
                        .coerceAtMost(queryEnd - dayStart.timeInMillis)
                    if (foreground <= 0L) null else appPackage to foreground
                }
                .groupBy({ it.first }, { it.second })
                .mapValues { (_, values) -> values.maxOrNull() ?: 0L }

            val dayKey = dayKey(dayStart.timeInMillis)
            for ((appPackage, foreground) in foregroundByPackage) {
                if (foreground <= 0L) continue
                val usage = stats.firstOrNull { it.packageName == appPackage }
                val activityStart = max(
                    usage?.firstTimeStamp ?: dayStart.timeInMillis,
                    dayStart.timeInMillis,
                )
                result.add(
                    mapOf(
                        "packageName" to appPackage,
                        "applicationName" to appLabel(appPackage),
                        "date" to dayKey,
                        "startTime" to activityStart,
                        "duration" to foreground,
                        "isForeground" to true,
                    ),
                )
            }
        }
        return result
    }

    private fun appLabel(appPackage: String): String = runCatching {
        val applicationInfo = packageManager.getApplicationInfo(appPackage, 0)
        packageManager.getApplicationLabel(applicationInfo).toString()
    }.getOrDefault(appPackage)

    private fun openApplication(appPackage: String): Boolean {
        if (appPackage.isBlank() || appPackage == packageName) return false
        val intent = packageManager.getLaunchIntentForPackage(appPackage) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun getBlockerStatus(): Map<String, Any> {
        val preferences = getSharedPreferences("unloop_blocker", Context.MODE_PRIVATE)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ).orEmpty()
        val expected = ComponentName(this, AppBlockerService::class.java).flattenToString()
        val systemEnabled = enabledServices
            .split(':')
            .any { ComponentName.unflattenFromString(it)?.flattenToString() == expected }
        return mapOf(
            "systemEnabled" to systemEnabled,
            "unloopEnabled" to preferences.getBoolean("blocker_enabled", false),
        )
    }

    private fun setBlockerEnabled(call: MethodCall) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        val packages = call.argument<List<String>>("packages").orEmpty()
        getSharedPreferences("unloop_blocker", Context.MODE_PRIVATE)
            .edit()
            .putBoolean("blocker_enabled", enabled)
            .putString("blocker_packages", JSONArray(packages).toString())
            .putBoolean("packages_dirty", true)
            .apply()
        AppBlockerService.refreshState(this)
    }

    private fun consumePendingBlockerEvent(): Map<String, Any?>? {
        val preferences = getSharedPreferences("unloop_blocker", Context.MODE_PRIVATE)
        val appPackage = preferences.getString("pending_package", null) ?: return null
        val appName = preferences.getString("pending_name", appPackage)
        preferences.edit()
            .remove("pending_package")
            .remove("pending_name")
            .apply()
        return mapOf("packageName" to appPackage, "appName" to appName)
    }

    private fun openSettings(action: String) {
        val intent = Intent(action).apply {
            data = if (action == Settings.ACTION_USAGE_ACCESS_SETTINGS) {
                Uri.fromParts("package", packageName, null)
            } else {
                null
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { startActivity(intent) }.onFailure {
            startActivity(
                Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        }
    }

    private fun dayKey(timestamp: Long): String {
        val calendar = Calendar.getInstance().apply { timeInMillis = timestamp }
        return "%04d-%02d-%02d".format(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
        )
    }
}
