import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceOptimizationService {
  static const MethodChannel _channel =
      MethodChannel('ph.redsync/device_optimizations');

  // UNIVERSAL DEVICE DETECTION FOR ALL BRANDS

  static Future<String> getDeviceBrand() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.manufacturer.toLowerCase();
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<int> getAndroidApiLevel() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      return 21; // Default to Android 5.0
    }
  }

  static Future<bool> isXiaomiDevice() async {
    final brand = await getDeviceBrand();
    return brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco');
  }

  static Future<bool> isVivoDevice() async {
    final brand = await getDeviceBrand();
    return brand.contains('vivo') || brand.contains('iqoo');
  }

  static Future<bool> isOppoDevice() async {
    final brand = await getDeviceBrand();
    return brand.contains('oppo') ||
        brand.contains('oneplus') ||
        brand.contains('realme');
  }

  static Future<bool> isHuaweiDevice() async {
    final brand = await getDeviceBrand();
    return brand.contains('huawei') || brand.contains('honor');
  }

  static Future<bool> isSamsungDevice() async {
    final brand = await getDeviceBrand();
    return brand.contains('samsung');
  }

  static Future<bool> isAndroid15OrHigher() async {
    final apiLevel = await getAndroidApiLevel();
    return apiLevel >= 35; // Android 15 is API 35
  }

  static Future<bool> isAndroid13OrHigher() async {
    final apiLevel = await getAndroidApiLevel();
    return apiLevel >= 33; // Android 13 is API 33
  }

  static Future<bool> isAndroid12OrHigher() async {
    final apiLevel = await getAndroidApiLevel();
    return apiLevel >= 31; // Android 12 is API 31
  }

  // UNIVERSAL OPTIMIZATION METHODS FOR ALL BRANDS AND RELEASE MODE

  static Future<void> requestAllCriticalPermissions() async {
    try {
      debugPrint(
          '🔥 [UNIVERSAL] Requesting ALL critical permissions for release mode...');

      // Core permissions that work on ALL devices
      await _safeInvoke('requestBatteryOptimizationExemption');
      await _safeInvoke('requestFullScreenIntentPermission');
      await _safeInvoke('openNotificationSettings');

      debugPrint('✅ [UNIVERSAL] Critical permissions requested');
    } catch (e) {
      debugPrint('❌ [UNIVERSAL] Failed to request permissions: $e');
    }
  }

  static Future<void> applyUniversalOptimizations() async {
    final brand = await getDeviceBrand();
    final apiLevel = await getAndroidApiLevel();
    final isRelease = kReleaseMode;

    debugPrint(
        '🔥 [UNIVERSAL] Device: $brand, API: $apiLevel, Release: $isRelease');

    // ALWAYS apply these optimizations in release mode
    if (isRelease) {
      debugPrint('🔥 [RELEASE MODE] Applying aggressive optimizations...');
      await requestAllCriticalPermissions();
    }

    // Brand-specific optimizations
    if (await isXiaomiDevice()) {
      debugPrint('🔥 [XIAOMI] Applying Xiaomi-specific optimizations...');
      await _safeInvoke('openXiaomiSettings');
    }

    if (await isVivoDevice()) {
      debugPrint('🔥 [VIVO] Applying Vivo-specific optimizations...');
      await _safeInvoke('openVivoSettings');
    }

    if (await isOppoDevice()) {
      debugPrint('🔥 [OPPO] Applying OPPO/OnePlus/Realme optimizations...');
      await _safeInvoke('openOppoSettings');
    }

    if (await isHuaweiDevice()) {
      debugPrint('🔥 [HUAWEI] Applying Huawei/Honor optimizations...');
      await _safeInvoke('openHuaweiSettings');
    }

    if (await isSamsungDevice()) {
      debugPrint('🔥 [SAMSUNG] Applying Samsung One UI optimizations...');
      await _safeInvoke('openSamsungSettings');
    }

    // Android version-specific optimizations
    if (await isAndroid15OrHigher()) {
      debugPrint('🔥 [ANDROID 15+] Applying Android 15+ optimizations...');
      await _safeInvoke('requestAndroid15Permissions');
    }

    if (await isAndroid13OrHigher()) {
      debugPrint('🔥 [ANDROID 13+] Applying Android 13+ optimizations...');
      await _safeInvoke('requestAndroid13Permissions');
    }
  }

  static Future<void> _safeInvoke(String method) async {
    try {
      await _channel.invokeMethod(method);
    } catch (e) {
      debugPrint('❌ [SAFE INVOKE] Failed to call $method: $e');
    }
  }

  // PUBLIC METHOD FOR EXTERNAL ACCESS
  static Future<void> safeInvoke(String method) async {
    await _safeInvoke(method);
  }

  // BACKGROUND SERVICE MANAGEMENT
  static Future<void> startBackgroundService() async {
    await _safeInvoke('startBackgroundService');
  }

  // PROCESS PERSISTENCE
  static Future<void> preventAppKilling() async {
    await _safeInvoke('preventAppKilling');
  }

  // Legacy methods for backward compatibility
  static Future<void> requestBatteryOptimizationExemption() async {
    await _safeInvoke('requestBatteryOptimizationExemption');
  }

  static Future<void> openNotificationSettings() async {
    await _safeInvoke('openNotificationSettings');
  }

  static Future<void> handleAllDeviceOptimizations() async {
    await applyUniversalOptimizations();
  }
}
