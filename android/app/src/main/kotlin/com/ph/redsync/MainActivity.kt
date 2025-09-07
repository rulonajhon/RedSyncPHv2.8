package com.ph.redsync

import io.flutter.embedding.android.FlutterActivity
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.content.ComponentName
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ph.redsync/device_optimizations"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryOptimizationExemption" -> {
                    requestBatteryOptimizationExemption()
                    result.success(null)
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "requestFullScreenIntentPermission" -> {
                    requestFullScreenIntentPermission()
                    result.success(null)
                }
                "openXiaomiSettings" -> {
                    openXiaomiSettings()
                    result.success(null)
                }
                "openVivoSettings" -> {
                    openVivoSettings()
                    result.success(null)
                }
                "openOppoSettings" -> {
                    openOppoSettings()
                    result.success(null)
                }
                "openHuaweiSettings" -> {
                    openHuaweiSettings()
                    result.success(null)
                }
                "openSamsungSettings" -> {
                    openSamsungSettings()
                    result.success(null)
                }
                "requestAndroid15Permissions" -> {
                    requestAndroid15Permissions()
                    result.success(null)
                }
                "requestAndroid13Permissions" -> {
                    requestAndroid13Permissions()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // UNIVERSAL BATTERY OPTIMIZATION METHOD FOR ALL BRANDS
    private fun requestBatteryOptimizationExemption() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${packageName}")
            }
            try {
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to general battery optimization settings
                val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(fallbackIntent)
            }
        }
    }
    
    // UNIVERSAL NOTIFICATION SETTINGS FOR ALL BRANDS
    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${packageName}")
            }
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Last resort - open main settings
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }
    
    // ANDROID 15+ FULL SCREEN INTENT PERMISSION
    private fun requestFullScreenIntentPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // Android 14+
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
                    data = Uri.parse("package:${packageName}")
                }
                startActivity(intent)
            } catch (e: Exception) {
                // Fallback to notification settings
                openNotificationSettings()
            }
        }
    }
    
    // ANDROID 15+ SPECIFIC PERMISSIONS
    private fun requestAndroid15Permissions() {
        if (Build.VERSION.SDK_INT >= 35) { // Android 15
            try {
                // Request exact alarm permission
                val exactAlarmIntent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:${packageName}")
                }
                startActivity(exactAlarmIntent)
            } catch (e: Exception) {
                requestFullScreenIntentPermission()
            }
        }
    }
    
    // ANDROID 13+ SPECIFIC PERMISSIONS
    private fun requestAndroid13Permissions() {
        if (Build.VERSION.SDK_INT >= 33) { // Android 13
            try {
                // Open notification permission if needed
                openNotificationSettings()
            } catch (e: Exception) {
                requestBatteryOptimizationExemption()
            }
        }
    }
    
    // XIAOMI/MIUI SPECIFIC SETTINGS
    private fun openXiaomiSettings() {
        val xiaomiIntents = listOf(
            // MIUI Security app autostart
            Intent().apply {
                setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"))
                putExtra("packageName", packageName)
            },
            // MIUI Power settings
            Intent().apply {
                setComponent(ComponentName("com.miui.powerkeeper", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"))
                putExtra("package_name", packageName)
            },
            // MIUI Background app refresh
            Intent().apply {
                setComponent(ComponentName("com.miui.securitycenter", "com.miui.powercenter.PowerSettings"))
                putExtra("package_name", packageName)
            }
        )
        
        tryIntents(xiaomiIntents)
    }
    
    // VIVO/FUNTOUCH OS SPECIFIC SETTINGS
    private fun openVivoSettings() {
        val vivoIntents = listOf(
            // Vivo iManager for autostart and background apps
            Intent().apply { 
                setClassName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.SoftPermissionDetailActivity")
                putExtra("packagename", packageName)
            },
            // Vivo autostart manager
            Intent().apply {
                setClassName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")
                putExtra("packageName", packageName)
            },
            // Vivo background app management
            Intent().apply {
                setClassName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BackgroundActivityManagerActivity")
                putExtra("packagename", packageName)
            }
        )
        
        tryIntents(vivoIntents)
    }
    
    // OPPO/COLOROS/ONEPLUS/REALME SPECIFIC SETTINGS
    private fun openOppoSettings() {
        val oppoIntents = listOf(
            // OPPO Security Center
            Intent().apply {
                setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.FakeActivity"))
                putExtra("packageName", packageName)
            },
            // OnePlus Security
            Intent().apply {
                setComponent(ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"))
                putExtra("packageName", packageName)
            },
            // Realme App Management
            Intent().apply {
                setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"))
                putExtra("packageName", packageName)
            }
        )
        
        tryIntents(oppoIntents)
    }
    
    // HUAWEI/EMUI/HONOR SPECIFIC SETTINGS
    private fun openHuaweiSettings() {
        val huaweiIntents = listOf(
            // Huawei Phone Manager
            Intent().apply {
                setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"))
                putExtra("packageName", packageName)
            },
            // Honor Phone Manager
            Intent().apply {
                setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"))
                putExtra("packageName", packageName)
            },
            // Huawei Power Genie
            Intent().apply {
                setComponent(ComponentName("com.huawei.powergenie", "com.huawei.powergenie.ui.HwPowerGenieMainActivity"))
                putExtra("packageName", packageName)
            }
        )
        
        tryIntents(huaweiIntents)
    }
    
    // SAMSUNG/ONE UI SPECIFIC SETTINGS
    private fun openSamsungSettings() {
        val samsungIntents = listOf(
            // Samsung Device Care
            Intent().apply {
                setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"))
                putExtra("package_name", packageName)
            },
            // Samsung Battery Optimization
            Intent().apply {
                action = "android.settings.APPLICATION_DETAILS_SETTINGS"
                data = Uri.parse("package:${packageName}")
            },
            // Samsung Smart Manager
            Intent().apply {
                setComponent(ComponentName("com.samsung.android.sm_cn", "com.samsung.android.sm.ui.ram.AutoRunActivity"))
                putExtra("package_name", packageName)
            }
        )
        
        tryIntents(samsungIntents)
    }
    
    // UNIVERSAL INTENT HANDLER - TRIES ALL INTENTS UNTIL ONE WORKS
    private fun tryIntents(intents: List<Intent>) {
        for (intent in intents) {
            try {
                startActivity(intent)
                return // Success - exit early
            } catch (e: Exception) {
                // Continue to next intent
            }
        }
        
        // If all brand-specific intents fail, fallback to general settings
        try {
            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${packageName}")
            }
            startActivity(fallbackIntent)
        } catch (e: Exception) {
            // Last resort - open main settings
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }
}
