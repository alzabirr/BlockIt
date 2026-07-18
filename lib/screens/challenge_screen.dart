import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/block_service.dart';
import '../services/usage_stats_service.dart';
import '../storage/hive_storage.dart';
import '../themes/app_theme.dart';
import '../widgets/ambient_background.dart';

enum FocusState { idle, running, paused, success, failed }

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  final HiveStorage _storage = HiveStorage();
  
  // Stats
  int _focusPoints = 0;
  int _completedSessions = 0;
  int _streak = 0;
  String _lastSuccessDate = '';

  // Timer state
  FocusState _state = FocusState.idle;
  int _selectedMinutes = 1;
  int _secondsRemaining = 1 * 60;
  Timer? _timer;
  Timer? _distractionCheckTimer;

  // Background distraction checking
  Map<String, int> _initialUsage = {};
  String _failedReason = '';

  // Confetti / Animations
  bool _showConfetti = false;
  late AnimationController _confettiController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadStats();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _confettiController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _showConfetti = false);
        }
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _distractionCheckTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    _focusPoints = _storage.getSetting('focus_points', 0) as int;
    _completedSessions = _storage.getSetting('focus_sessions_count', 0) as int;
    _streak = _storage.getSetting('focus_streak', 0) as int;
    _lastSuccessDate = _storage.getSetting('focus_last_success_date', '') as String;

    final questStateStr = _storage.getSetting('focus_quest_state', 'idle') as String;
    if (questStateStr == 'running') {
      final endTimestamp = _storage.getSetting('focus_quest_end_timestamp', 0) as int;
      _selectedMinutes = _storage.getSetting('focus_quest_selected_minutes', 1) as int;

      final rawUsage = _storage.getSetting('focus_quest_initial_usage', {}) as Map;
      _initialUsage = rawUsage.map((k, v) => MapEntry(k.toString(), v as int));

      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = (endTimestamp - now) ~/ 1000;

      if (remaining > 0) {
        setState(() {
          _state = FocusState.running;
          _secondsRemaining = remaining;
        });
        _resumeTimer();
      } else {
        await _checkOfflineQuestCompletion();
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  Future<bool> _hasCheated() async {
    final blockService = Provider.of<BlockService>(context, listen: false);
    final limits = blockService.limits;

    try {
      final currentUsage = await UsageStatsService.getTodayUsage();
      for (var limit in limits) {
        final pkg = limit.packageName;
        final initialMin = _initialUsage[pkg] ?? 0;
        final currentMin = currentUsage[pkg] ?? 0;

        if (currentMin > initialMin + 5000) {
          return true;
        }
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }

  void _resumeTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _completeFocusQuest();
      }
    });

    _distractionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final cheated = await _hasCheated();
      if (cheated) {
        _failFocusQuest('You opened a blocked app during your Focus Quest.');
      }
    });
  }

  Future<void> _checkOfflineQuestCompletion() async {
    final cheated = await _hasCheated();
    if (cheated) {
      _storage.saveSetting('focus_quest_state', 'failed');
      setState(() {
        _state = FocusState.failed;
        _failedReason = 'You opened a blocked app while the app was closed.';
        _streak = 0;
        _storage.saveSetting('focus_streak', _streak);
      });
    } else {
      _completeFocusQuest();
    }
  }

  String get _levelName {
    if (_focusPoints < 50) return '🌱 Seedling';
    if (_focusPoints < 150) return '⏱️ Time Weaver';
    if (_focusPoints < 300) return '⚡ Focus Warrior';
    return '🌌 Zen Master';
  }

  int get _pointsForCurrentLevel {
    if (_focusPoints < 50) return 0;
    if (_focusPoints < 150) return 50;
    if (_focusPoints < 300) return 150;
    return 300;
  }

  int get _pointsForNextLevel {
    if (_focusPoints < 50) return 50;
    if (_focusPoints < 150) return 150;
    if (_focusPoints < 300) return 300;
    return 1000; // max/infinite tier representation
  }

  int get _pointsReward {
    switch (_selectedMinutes) {
      case 1:
        return 10;
      case 5:
        return 25;
      case 10:
        return 50;
      default:
        return 10;
    }
  }

  Future<void> _startFocusQuest() async {
    HapticFeedback.mediumImpact();
    
    // Capture current usage stats for all apps
    try {
      _initialUsage = await UsageStatsService.getTodayUsage();
    } catch (e) {
      _initialUsage = {};
    }

    final endTimestamp = DateTime.now().millisecondsSinceEpoch + (_selectedMinutes * 60 * 1000);
    _storage.saveSetting('focus_quest_state', 'running');
    _storage.saveSetting('focus_quest_end_timestamp', endTimestamp);
    _storage.saveSetting('focus_quest_selected_minutes', _selectedMinutes);
    _storage.saveSetting('focus_quest_initial_usage', _initialUsage);

    setState(() {
      _state = FocusState.running;
      _secondsRemaining = _selectedMinutes * 60;
      _failedReason = '';
    });

    _resumeTimer();
  }

  void _failFocusQuest(String reason) {
    _timer?.cancel();
    _distractionCheckTimer?.cancel();
    HapticFeedback.heavyImpact();

    _storage.saveSetting('focus_quest_state', 'failed');

    setState(() {
      _state = FocusState.failed;
      _failedReason = reason;
      // Reset streak on failure
      _streak = 0;
      _storage.saveSetting('focus_streak', _streak);
    });
  }

  void _completeFocusQuest() {
    _timer?.cancel();
    _distractionCheckTimer?.cancel();
    HapticFeedback.vibrate();

    _storage.saveSetting('focus_quest_state', 'success');

    final today = DateTime.now();

    // Calculate streak
    int newStreak = _streak;
    if (_lastSuccessDate.isNotEmpty) {
      final lastDate = DateTime.tryParse(_lastSuccessDate) ?? today.subtract(const Duration(days: 2));
      final difference = today.difference(lastDate).inDays;
      if (difference == 1) {
        newStreak++;
      } else if (difference > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    _focusPoints += _pointsReward;
    _completedSessions += 1;
    _streak = newStreak;
    _lastSuccessDate = today.toIso8601String();

    _storage.saveSetting('focus_points', _focusPoints);
    _storage.saveSetting('focus_sessions_count', _completedSessions);
    _storage.saveSetting('focus_streak', _streak);
    _storage.saveSetting('focus_last_success_date', _lastSuccessDate);

    setState(() {
      _state = FocusState.success;
      _showConfetti = true;
    });

    _confettiController.forward(from: 0);
  }

  void _giveUp() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Give up Focus Quest?'),
        content: const Text(
          'Leaving now will break your streak and fail the quest.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Keep Focusing'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Give Up'),
            onPressed: () {
              Navigator.pop(context);
              _failFocusQuest('You chose to give up.');
            },
          ),
        ],
      ),
    );
  }

  void _resetToIdle() {
    _storage.saveSetting('focus_quest_state', 'idle');
    setState(() {
      _state = FocusState.idle;
      _secondsRemaining = _selectedMinutes * 60;
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        final levelProgress = (_focusPoints - _pointsForCurrentLevel) /
            (_pointsForNextLevel - _pointsForCurrentLevel);

        return Scaffold(
          backgroundColor: bgLight,
          body: Stack(
            children: [
              AmbientBackground(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Header / Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Focus Quest',
                                  style: headingStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ).animate().fadeIn(duration: 400.ms),
                                const SizedBox(height: 4),
                                Text(
                                  'Stay distraction-free, earn rank',
                                  style: bodyStyle(color: textMid, fontSize: 14),
                                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '🔥 $_streak',
                                    style: bodyStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Level Progress Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.12),
                                accent.withValues(alpha: 0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _levelName,
                                        style: headingStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_focusPoints XP Total • $_completedSessions Quests Completed',
                                        style: bodyStyle(
                                          color: textMid,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: levelProgress.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: textMid.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 12),

                        // Timer Circle View
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, -0.6),
                            child: _buildTimerContent(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Confetti overlay on check-in
              if (_showConfetti)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ConfettiPainter(
                              _confettiController.value, _focusPoints),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerContent(bool isDark) {
    final double progress = _state == FocusState.idle
        ? 1.0
        : (_secondsRemaining / (_selectedMinutes * 60));

    switch (_state) {
      case FocusState.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular timer selector view
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textMid.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_selectedMinutes:00',
                      style: headingStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+$_pointsReward XP reward',
                      style: bodyStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [1, 5, 10].map((mins) {
                final isSelected = _selectedMinutes == mins;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedMinutes = mins;
                      _secondsRemaining = mins * 60;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary
                          : primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? primary : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '$mins min',
                      style: bodyStyle(
                        color: isSelected ? Colors.white : textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Start Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _startFocusQuest,
              child: Container(
                width: 200,
                height: 56,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(buttonRadius),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'Start Focus Quest',
                  style: bodyStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );

      case FocusState.running:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Countdown Ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.08 * _pulseController.value),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: progress, end: progress),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor: primary.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(primary),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(_secondsRemaining),
                        style: headingStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Do not open blocked apps',
                        style: bodyStyle(
                          color: textMid,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Give Up Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _giveUp,
              child: Container(
                width: 160,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(buttonRadius),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Give Up',
                  style: bodyStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );

      case FocusState.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Checkmark
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                CupertinoIcons.checkmark_alt,
                color: Colors.green,
                size: 48,
              ),
            ).animate().scale(
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),
            Text(
              'Quest Complete!',
              style: headingStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You earned +$_pointsReward XP!',
              style: bodyStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 48),

            // Continue Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _resetToIdle,
              child: Container(
                width: 180,
                height: 52,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(buttonRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Return to Quest',
                  style: bodyStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        );

      case FocusState.failed:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warn Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ).animate().shake(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                'Quest Failed!',
                style: headingStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _failedReason,
                textAlign: TextAlign.center,
                style: bodyStyle(
                  color: textMid,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

              // Retry Button
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _resetToIdle,
                child: Container(
                  width: 180,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Try Again',
                    style: bodyStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// Confetti painter
class _ConfettiPainter extends CustomPainter {
  final double progress;
  final int seed;
  late final math.Random _rnd;

  static const int _count = 80;
  static const List<Color> _colors = [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF007AFF),
    Color(0xFFAF52DE),
    Colors.white,
  ];

  _ConfettiPainter(this.progress, this.seed) {
    _rnd = math.Random(seed);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _count; i++) {
      final startX = _rnd.nextDouble() * size.width;
      final vy = 0.3 + _rnd.nextDouble() * 0.7;
      final vx = (_rnd.nextDouble() - 0.5) * 0.4;
      final rotate = _rnd.nextDouble() * math.pi * 4 * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final particleSize = 5.0 + _rnd.nextDouble() * 7.0;

      final x = startX + vx * size.width * progress;
      final y = -20.0 + vy * size.height * progress * 1.2;

      paint.color = _colors[i % _colors.length].withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotate);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize,
            height: particleSize * 0.45,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
