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
import 'set_limit_screen.dart';
import '../storage/hive_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  int _challengeDay = 1;
  bool _isCheckedInToday = false;
  final _storage = HiveStorage();

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
    _loadChallengeProgress();
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
      _loadChallengeProgress();
    }
  }

  void _loadChallengeProgress() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    String? startStr = _storage.getSetting('challenge_start_date', null) as String?;
    if (startStr == null) {
      startStr = now.toIso8601String();
      _storage.saveSetting('challenge_start_date', startStr);
    }
    final startDate = DateTime.parse(startStr);
    final diffDays = now.difference(startDate).inDays + 1;
    
    _challengeDay = diffDays.clamp(1, 42);
    
    final List<dynamic> checkIns = _storage.getSetting('challenge_check_ins', []) as List<dynamic>;
    _isCheckedInToday = checkIns.contains(todayStr);
    
    if (mounted) {
      setState(() {});
    }
  }

  void _checkInChallenge() {
    HapticFeedback.heavyImpact();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final List<dynamic> checkIns = List.from(_storage.getSetting('challenge_check_ins', []) as List<dynamic>);
    
    if (!checkIns.contains(todayStr)) {
      checkIns.add(todayStr);
      _storage.saveSetting('challenge_check_ins', checkIns);
      setState(() {
        _isCheckedInToday = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Day $_challengeDay check-in complete! Stay strong!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: accent,
        ),
      );
    }
  }

  void _toggleDarkMode() {
    HapticFeedback.lightImpact();
    darkModeNotifier.value = !darkModeNotifier.value;
  }

  void _showEditLimitBottomSheet(AppLimit limit) {
    HapticFeedback.mediumImpact();
    double sliderValue = limit.limitMinutes.toDouble();
    String currentBlockingMode = limit.blockingMode;
    bool isCurious = limit.isCuriousMode;
    double scrollLimit = limit.maxScrolls.toDouble();
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
                          style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // 1. Time Limit Slider
                        Text(
                          'Daily App Time: $durationText',
                          style: bodyStyle(fontWeight: FontWeight.bold, color: primary),
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

                        // 2. Blocking Mode Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Restriction Scope', style: bodyStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Text('Shorts & Reels Only', style: bodyStyle(color: currentBlockingMode == 'shorts_reels' ? Colors.white : textDark)),
                                selected: currentBlockingMode == 'shorts_reels',
                                selectedColor: primary,
                                onSelected: (val) {
                                  if (val) setModalState(() => currentBlockingMode = 'shorts_reels');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: Text('Block Entire App', style: bodyStyle(color: currentBlockingMode == 'all' ? Colors.white : textDark)),
                                selected: currentBlockingMode == 'all',
                                selectedColor: primary,
                                onSelected: (val) {
                                  if (val) setModalState(() => currentBlockingMode = 'all');
                                },
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // 3. Curious Mode Switch (Only applicable if blocking Mode is shorts_reels)
                        if (currentBlockingMode == 'shorts_reels') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Curious Mode', style: bodyStyle(fontWeight: FontWeight.bold)),
                                  Text('Allow scroll limit before block', style: bodyStyle(color: textMid, fontSize: 12)),
                                ],
                              ),
                              Switch(
                                value: isCurious,
                                activeColor: primary,
                                onChanged: (val) {
                                  setModalState(() => isCurious = val);
                                },
                              ),
                            ],
                          ),
                          if (isCurious) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Max Scrolls: ${scrollLimit.round()}', style: bodyStyle(color: primary)),
                              ],
                            ),
                            Slider(
                              value: scrollLimit,
                              min: 1,
                              max: 20,
                              divisions: 19,
                              activeColor: accent,
                              inactiveColor: accent.withValues(alpha: 0.2),
                              onChanged: (val) {
                                setModalState(() => scrollLimit = val);
                              },
                            ),
                          ],
                          const Divider(height: 32),
                        ],

                        // 4. Action Type dropdown/selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Preferred Action', style: bodyStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: currentAction,
                          dropdownColor: surface,
                          style: bodyStyle(),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            DropdownMenuItem(value: 'close_player', child: Text('Close video (Go Back)', style: bodyStyle())),
                            DropdownMenuItem(value: 'exit_app', child: Text('Exit App (Go Home)', style: bodyStyle())),
                            DropdownMenuItem(value: 'lock_screen', child: Text('Lock Screen (API 28+)', style: bodyStyle())),
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
                                      content: Text('Limit deleted for ${limit.appName}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(buttonRadius),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Delete Limit',
                                    style: bodyStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
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
                                    blockingMode: currentBlockingMode,
                                    isCuriousMode: isCurious,
                                    maxScrolls: scrollLimit.round(),
                                    actionType: currentAction,
                                  );
                                  HapticFeedback.mediumImpact();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Limit updated for ${limit.appName}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: primary,
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(buttonRadius),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Save',
                                    style: bodyStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
    final blockService = Provider.of<BlockService>(context);

    // Calculate total time
    int totalLimit = 0;
    int totalUsed = 0;
    int blockedCount = 0;

    for (var l in blockService.limits) {
      totalLimit += l.limitMinutes;
      totalUsed += l.usedMinutes;
      if (l.isBlocked) blockedCount++;
    }

    final overallProgress = totalLimit > 0 ? (totalUsed / totalLimit).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NoScroll',
                        style: headingStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 4),
                      Text(
                        'Quit the doomscrolling loop',
                        style: bodyStyle(color: textMid, fontSize: 14),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: surface.withValues(alpha: isDarkMode ? 0.3 : 0.8),
                      child: IconButton(
                        icon: Icon(
                          isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon,
                          color: textDark,
                        ),
                        onPressed: _toggleDarkMode,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  const SizedBox(height: 8),

                  // 6-Week Challenge Widget
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent.withValues(alpha: 0.15), primary.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(CupertinoIcons.flame_fill, color: Colors.orangeAccent, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  '6-Week NoScroll Challenge',
                                  style: headingStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Day $_challengeDay/42',
                                style: bodyStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Live present, save attention span. Reclaim hours wasted scrolling short videos.',
                          style: bodyStyle(color: textDark.withValues(alpha: 0.8), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _challengeDay / 42.0,
                                  minHeight: 12,
                                  backgroundColor: textMid.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: _isCheckedInToday ? null : _checkInChallenge,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isCheckedInToday ? Colors.grey.withValues(alpha: 0.3) : accent,
                                  borderRadius: BorderRadius.circular(buttonRadius),
                                ),
                                child: Text(
                                  _isCheckedInToday ? 'Checked In' : 'Check In',
                                  style: bodyStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97)),

                  // Overview Glassmorphic Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [primary.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]
                            : [primary.withValues(alpha: 0.08), accent.withValues(alpha: 0.03)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Usage',
                                style: headingStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalUsed mins of $totalLimit mins used',
                                style: bodyStyle(color: textMid, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: blockedCount > 0
                                          ? Colors.redAccent.withValues(alpha: 0.15)
                                          : Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      blockedCount > 0 ? '$blockedCount blocked' : 'All safe',
                                      style: bodyStyle(
                                        color: blockedCount > 0 ? Colors.redAccent : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Sleek circular usage chart
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressIndicator(
                                value: overallProgress,
                                strokeWidth: 8,
                                backgroundColor: primary.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  overallProgress >= 0.9 ? Colors.redAccent : primary,
                                ),
                              ),
                            ),
                            Text(
                              '${(overallProgress * 100).round()}%',
                              style: headingStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 24),

                  // Missing Permissions Panel
                  if (!blockService.hasPermission || !blockService.hasAccessibilityPermission)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: isDarkMode ? 0.1 : 0.15),
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
                              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Permissions Required',
                                style: headingStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Please grant these system permissions so NoScroll can track usage and block Reels/Shorts.',
                            style: bodyStyle(height: 1.4, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          if (!blockService.hasPermission)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Usage Statistics Access', style: bodyStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Required to track today\'s screen time', style: bodyStyle(color: textMid, fontSize: 12)),
                              trailing: Icon(CupertinoIcons.arrow_right_circle_fill, color: primary),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                UsageStatsService.requestUsagePermission();
                              },
                            ),
                          if (!blockService.hasPermission && !blockService.hasAccessibilityPermission)
                            const Divider(height: 1),
                          if (!blockService.hasAccessibilityPermission)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Accessibility Blocker Service', style: bodyStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Required to detect and block short videos scrolling', style: bodyStyle(color: textMid, fontSize: 12)),
                              trailing: Icon(CupertinoIcons.arrow_right_circle_fill, color: primary),
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
                        style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (context) => const SetLimitScreen()),
                          );
                        },
                        child: Text(
                          '+ Add Limit',
                          style: bodyStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 15),
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
                          Icon(CupertinoIcons.app_badge_fill, size: 64, color: textMid.withValues(alpha: 0.3)),
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
                      
                      String detailText = '';
                      if (limit.blockingMode == 'shorts_reels') {
                        detailText = 'Shorts/Reels Blocked';
                        if (limit.isCuriousMode) {
                          detailText += ' (Curious Mode: Max ${limit.maxScrolls} scrolls)';
                        }
                      } else {
                        detailText = 'Entire App Blocked';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: isDarkMode ? 0.4 : 0.8),
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(
                            color: isBlocked
                                ? Colors.redAccent.withValues(alpha: 0.3)
                                : textDark.withValues(alpha: 0.05),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () => _showEditLimitBottomSheet(limit),
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: (isBlocked
                                                      ? Colors.redAccent
                                                      : isApproaching
                                                          ? Colors.orangeAccent
                                                          : primary)
                                                  .withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              limit.blockingMode == 'shorts_reels'
                                                  ? CupertinoIcons.videocam_fill
                                                  : CupertinoIcons.lock_fill,
                                              color: isBlocked
                                                  ? Colors.redAccent
                                                  : isApproaching
                                                      ? Colors.orangeAccent
                                                      : primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  limit.appName,
                                                  style: bodyStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  limit.packageName,
                                                  style: bodyStyle(color: textMid, fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${limit.usedMinutes} / ${limit.limitMinutes}m',
                                          style: headingStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isBlocked
                                                ? Colors.redAccent
                                                : isApproaching
                                                    ? Colors.orangeAccent
                                                    : textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isBlocked
                                                ? Colors.redAccent.withValues(alpha: 0.1)
                                                : Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isBlocked ? 'Blocked' : 'Active',
                                            style: bodyStyle(
                                              color: isBlocked ? Colors.redAccent : Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  detailText,
                                  style: bodyStyle(fontSize: 12, color: textMid, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: limit.progress,
                                    minHeight: 6,
                                    backgroundColor: textMid.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (context) => const SetLimitScreen()),
          );
        },
        backgroundColor: primary,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: Text('Add Limit', style: bodyStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().fadeIn(delay: 600.ms).scale(),
    );
  }
}
