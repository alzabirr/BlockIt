import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_limit.dart';
import 'usage_stats_service.dart';

class BlockService extends ChangeNotifier {
  static const String _limitsKey = 'app_limits';
  static const String _blockedPackagesKey = 'blocked_packages';

  List<AppLimit> _limits = [];
  bool _hasPermission = false;
  bool _hasAccessibilityPermission = false;

  List<AppLimit> get limits => _limits;
  bool get hasPermission => _hasPermission;
  bool get hasAccessibilityPermission => _hasAccessibilityPermission;

  BlockService() {
    _init();
  }

  Future<void> _init() async {
    await checkPermission();
    await checkAccessibilityPermission();
    await loadLimits();
    await updateUsage();
  }

  Future<void> checkPermission() async {
    _hasPermission = await UsageStatsService.hasUsagePermission();
    notifyListeners();
  }

  Future<void> checkAccessibilityPermission() async {
    _hasAccessibilityPermission = await UsageStatsService.hasAccessibilityPermission();
    notifyListeners();
  }

  Future<void> loadLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? limitsJson = prefs.getString(_limitsKey);

    if (limitsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(limitsJson);
        _limits = decoded.map((item) => AppLimit.fromJson(item)).toList();
      } catch (e) {
        print('Error decoding limits: $e');
        _setDefaultLimits();
      }
    } else {
      _setDefaultLimits();
    }
    notifyListeners();
  }

  void _setDefaultLimits() {
    _limits = [
      AppLimit(
        packageName: 'com.facebook.katana',
        appName: 'Facebook',
        limitMinutes: 60,
      ),
      AppLimit(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        limitMinutes: 60,
      ),
      AppLimit(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        limitMinutes: 60,
      ),
    ];
    _saveLimitsToDisk();
  }

  Future<void> _saveLimitsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_limits.map((l) => l.toJson()).toList());
    await prefs.setString(_limitsKey, encoded);
  }

  Future<void> updateLimit(String packageName, String appName, int limitMinutes) async {
    final index = _limits.indexWhere((l) => l.packageName == packageName);
    if (index >= 0) {
      _limits[index] = _limits[index].copyWith(
        appName: appName,
        limitMinutes: limitMinutes,
      );
    } else {
      _limits.add(AppLimit(
        packageName: packageName,
        appName: appName,
        limitMinutes: limitMinutes,
      ));
    }
    await _saveLimitsToDisk();
    await updateUsage();
  }

  Future<void> deleteLimit(String packageName) async {
    _limits.removeWhere((l) => l.packageName == packageName);
    await _saveLimitsToDisk();
    await updateUsage();
  }

  Future<void> updateUsage() async {
    _hasPermission = await UsageStatsService.hasUsagePermission();
    _hasAccessibilityPermission = await UsageStatsService.hasAccessibilityPermission();
    if (!_hasPermission) return;

    final Map<String, int> todayUsage = await UsageStatsService.getTodayUsage();
    List<String> blockedPackages = [];

    for (int i = 0; i < _limits.length; i++) {
      final limit = _limits[i];
      final usageMs = todayUsage[limit.packageName] ?? 0;
      final usedMins = (usageMs / 1000 / 60).round();

      final isBlocked = usedMins >= limit.limitMinutes;
      _limits[i] = limit.copyWith(
        usedMinutes: usedMins,
        isBlocked: isBlocked,
      );

      if (isBlocked) {
        blockedPackages.add(limit.packageName);
      }
    }

    // Persist blocked packages list for native BlockAccessibilityService to read
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_blockedPackagesKey, blockedPackages);

    notifyListeners();
  }
}
