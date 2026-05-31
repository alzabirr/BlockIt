import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_limit.dart';
import 'screens/home_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/block_service.dart';
import 'services/usage_stats_service.dart';
import 'themes/app_theme.dart';

import 'storage/hive_storage.dart';

// The callback function must be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Service started
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _checkUsage();
  }

  Future<void> _checkUsage() async {
    try {
      // Get today's usage from native MethodChannel
      final Map<String, int> todayUsage = await UsageStatsService.getTodayUsage();

      // Load limits from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? limitsJson = prefs.getString('app_limits');
      if (limitsJson != null) {
        final List<dynamic> decoded = jsonDecode(limitsJson);
        final List<AppLimit> limits = decoded.map((item) => AppLimit.fromJson(item)).toList();

        List<String> blockedPackages = [];
        for (var limit in limits) {
          final usageMs = todayUsage[limit.packageName] ?? 0;
          final usedMins = (usageMs / 1000 / 60).round();
          if (usedMins >= limit.limitMinutes) {
            blockedPackages.add(limit.packageName);
          }
        }

        // Write blocked packages to SharedPreferences
        await prefs.setStringList('blocked_packages', blockedPackages);
      }
    } catch (e) {
      print('Error in background repeat task: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Service destroyed
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();

  // Set status bar and system navigation bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize foreground task options
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'screen_guard_service',
      channelName: 'Screen Guard Service',
      channelDescription: 'Monitors screen time limits in the background.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(60000), // 1 minute
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // Start foreground task service
  if (!await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Screen Guard Active',
      notificationText: 'Monitoring your daily app limits...',
      callback: startCallback,
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => BlockService(),
      child: const NoScrollApp(),
    ),
  );
}

class NoScrollApp extends StatelessWidget {
  const NoScrollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Screen Guard',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: const Color(0xFF5E5CE6),
            scaffoldBackgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1C1C1E),
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarContrastEnforced: false,
                systemStatusBarContrastEnforced: false,
              ),
            ),
            cupertinoOverrideTheme: CupertinoThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primaryColor: const Color(0xFF5E5CE6),
              barBackgroundColor: isDark ? const Color(0xCC121212) : const Color(0xCCFFFFFF),
              scaffoldBackgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
              textTheme: const CupertinoTextThemeData(primaryColor: Color(0xFF5E5CE6)),
            ),
          ),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}
