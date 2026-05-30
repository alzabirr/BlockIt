import 'package:flutter/services.dart';

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel('screen_guard/usage');

  static Future<Map<String, int>> getTodayUsage() async {
    try {
      final Map<dynamic, dynamic>? usage = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTodayUsage');
      if (usage == null) return {};
      return usage.map((key, value) => MapEntry(key.toString(), value as int));
    } catch (e) {
      print('Error getting today usage: $e');
      return {};
    }
  }

  static Future<bool> hasUsagePermission() async {
    try {
      final bool? hasPermission = await _channel.invokeMethod<bool>('hasUsagePermission');
      return hasPermission ?? false;
    } catch (e) {
      print('Error checking usage permission: $e');
      return false;
    }
  }

  static Future<void> requestUsagePermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } catch (e) {
      print('Error requesting usage permission: $e');
    }
  }

  static Future<bool> hasAccessibilityPermission() async {
    try {
      final bool? hasPermission = await _channel.invokeMethod<bool>('hasAccessibilityPermission');
      return hasPermission ?? false;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      return false;
    }
  }

  static Future<void> requestAccessibilityPermission() async {
    try {
      await _channel.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      print('Error requesting accessibility permission: $e');
    }
  }
}
