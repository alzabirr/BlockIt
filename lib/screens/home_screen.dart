import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_limit.dart';
import '../services/block_service.dart';
import '../services/usage_stats_service.dart';
import '../themes/app_theme.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start periodic usage refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        context.read<BlockService>().updateUsage();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh permissions and usage when user comes back to the app
      final service = context.read<BlockService>();
      service.checkPermission();
      service.checkAccessibilityPermission();
      service.updateUsage();
    }
  }

  void _showEditLimitBottomSheet(AppLimit limit) {
    HapticFeedback.mediumImpact();
    double sliderValue = limit.limitMinutes.toDouble();
    String currentAction = limit.actionType;

    final blockService = context.read<BlockService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hours = (sliderValue / 60).floor();
            final minutes = (sliderValue % 60).round();
            String durationText = '';
            if (hours > 0) {
              durationText += '$hours hr ';
            }
            if (minutes > 0 || hours == 0) {
              durationText += '$minutes min';
            }

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(cardRadius),
                topRight: Radius.circular(cardRadius),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(cardRadius),
                      topRight: Radius.circular(cardRadius),
                    ),
                    border: Border.all(
                      color: textDark.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: textMid.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Configure limit for ${limit.appName}',
                          style: headingStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // 1. Time Limit Slider
                        Text(
                          'Daily App Time: $durationText',
                          style: bodyStyle(
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: sliderValue,
                          min: 15,
                          max: 480,
                          divisions: 31,
                          activeColor: primary,
                          inactiveColor: primary.withValues(alpha: 0.2),
                          onChanged: (val) {
                            setModalState(() {
                              sliderValue = val;
                            });
                          },
                        ),

                        const Divider(height: 32),

                        // 2. Action Type dropdown/selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Preferred Action',
                              style: bodyStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: currentAction,
                          dropdownColor: surface,
                          style: bodyStyle(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'exit_app',
                              child: Text(
                                'Exit App (Go Home)',
                                style: bodyStyle(),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'lock_screen',
                              child: Text(
                                'Lock Screen (API 28+)',
                                style: bodyStyle(),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => currentAction = val);
                            }
                          },
                        ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  blockService.deleteLimit(limit.packageName);
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Limit deleted for ${limit.appName}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      buttonRadius,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Delete Limit',
                                    style: bodyStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  blockService.updateLimit(
                                    limit.packageName,
                                    limit.appName,
                                    sliderValue.round(),
                                    blockingMode: 'all',
                                    isCuriousMode: false,
                                    maxScrolls: 0,
                                    actionType: currentAction,
                                  );
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Limit updated for ${limit.appName}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: primary,
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(
                                      buttonRadius,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Save',
                                    style: bodyStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        final blockService = Provider.of<BlockService>(context);

        return Scaffold(
          backgroundColor: bgLight,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                'NoScroll',
                                style: headingStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.1, end: 0),
                          const SizedBox(height: 4),
                          Text(
                            'Quit the doomscrolling loop',
                            style: bodyStyle(color: textMid, fontSize: 14),
                          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                        ],
                      ),
                      // Dark mode button removed as requested
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    children: [
                      const SizedBox(height: 8),

                      // Missing Permissions Panel
                      if (!blockService.hasPermission ||
                          !blockService.hasAccessibilityPermission)
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(
                              alpha: isDarkMode ? 0.1 : 0.15,
                            ),
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons
                                        .exclamationmark_triangle_fill,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Permissions Required',
                                    style: headingStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Please grant these system permissions so NoScroll can track usage and block apps after their limits.',
                                style: bodyStyle(height: 1.4, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              if (!blockService.hasPermission)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Usage Statistics Access',
                                    style: bodyStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Required to track today\'s screen time',
                                    style: bodyStyle(
                                      color: textMid,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(
                                    CupertinoIcons.arrow_right_circle_fill,
                                    color: primary,
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    UsageStatsService.requestUsagePermission();
                                  },
                                ),
                              if (!blockService.hasPermission &&
                                  !blockService.hasAccessibilityPermission)
                                const Divider(height: 1),
                              if (!blockService.hasAccessibilityPermission)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Accessibility Blocker Service',
                                    style: bodyStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Required to close or lock blocked apps',
                                    style: bodyStyle(
                                      color: textMid,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Icon(
                                    CupertinoIcons.arrow_right_circle_fill,
                                    color: primary,
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    UsageStatsService.requestAccessibilityPermission();
                                  },
                                ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tracked Apps',
                            style: headingStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // App list
                      if (blockService.limits.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.app_badge_fill,
                                size: 64,
                                color: textMid.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No app limits set yet.',
                                style: bodyStyle(color: textMid, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      else
                        ...blockService.limits.map((limit) {
                          final isApproaching = limit.progress >= 0.8;
                          final isBlocked = limit.isBlocked;

                          const detailText = 'Entire App Blocked';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: surface.withValues(
                                alpha: isDarkMode ? 0.4 : 0.8,
                              ),
                              borderRadius: BorderRadius.circular(cardRadius - 4),
                              border: Border.all(
                                color: isBlocked
                                    ? Colors.redAccent.withValues(alpha: 0.3)
                                    : textDark.withValues(alpha: 0.05),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => _showEditLimitBottomSheet(limit),
                              borderRadius: BorderRadius.circular(cardRadius - 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              FutureBuilder<AppInfo?>(
                                                future:
                                                    InstalledApps.getAppInfo(
                                                      limit.packageName,
                                                    ),
                                                builder: (context, snapshot) {
                                                  final hasIcon =
                                                      snapshot.hasData &&
                                                      snapshot.data?.icon !=
                                                          null;
                                                  return Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (isBlocked
                                                                  ? Colors
                                                                        .redAccent
                                                                  : isApproaching
                                                                  ? Colors
                                                                        .orangeAccent
                                                                  : primary)
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: hasIcon
                                                        ? ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            child: Image.memory(
                                                              snapshot
                                                                  .data!
                                                                  .icon!,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        : Icon(
                                                            CupertinoIcons
                                                                .lock_fill,
                                                            color: isBlocked
                                                                ? Colors
                                                                      .redAccent
                                                                : isApproaching
                                                                ? Colors
                                                                      .orangeAccent
                                                                : primary,
                                                            size: 16,
                                                          ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      limit.appName,
                                                      style: bodyStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${limit.usedMinutes}/${limit.limitMinutes}m',
                                              style: headingStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isBlocked
                                                    ? Colors.redAccent
                                                    : isApproaching
                                                    ? Colors.orangeAccent
                                                    : textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isBlocked
                                                    ? Colors.redAccent
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                    : Colors.green.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isBlocked
                                                    ? 'Blocked'
                                                    : 'Active',
                                                style: bodyStyle(
                                                  color: isBlocked
                                                      ? Colors.redAccent
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: limit.progress,
                                        minHeight: 4,
                                        backgroundColor: textMid.withValues(
                                          alpha: 0.1,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              isBlocked
                                                  ? Colors.redAccent
                                                  : isApproaching
                                                  ? Colors.orangeAccent
                                                  : primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
                        }),

                      const SizedBox(height: 80), // bottom margin
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
