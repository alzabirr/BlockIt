import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../storage/hive_storage.dart';
import '../themes/app_theme.dart';

// Daily motivational quotes to avoid doomscrolling
const List<String> _motivationalQuotes = [
  "Your attention is your most valuable resource. Guard it fiercely.",
  "Every scroll you resist is a moment you choose yourself.",
  "Real life happens outside the feed. Go live it.",
  "The best things in life are found by looking up, not at a screen.",
  "Boredom is the birthplace of creativity. Embrace it.",
  "You are not missing out. You are opting in — to yourself.",
  "Less scrolling, more living. One day at a time.",
  "The world is far more interesting than any algorithm.",
  "Silence your feed. Amplify your focus.",
  "Every great journey begins with putting the phone down.",
  "Peace of mind is just one tab close away.",
  "Your future self is grateful for every scroll you skipped.",
  "Be present. The reel will always wait. Your life will not.",
  "Reclaim your hours. Reclaim your power.",
  "Disconnect to reconnect — with yourself.",
  "The highlight reel is not real life.",
  "Deep work beats shallow scrolling, every time.",
  "Today's discipline is tomorrow's freedom.",
  "You control the feed, not the other way around.",
  "Attention is the new currency. Spend it wisely.",
  "Stillness is productive. Let the mind breathe.",
  "Your story is written offline.",
  "Challenge accepted. Scroll rejected.",
  "Boredom is okay. It passes. Unlike wasted hours.",
  "A moment of rest is worth a thousand reels.",
  "One week stronger. Keep going.",
  "Halfway there. You're building a habit that lasts.",
  "Eyes up. The best views have no filter.",
  "Your focus is a muscle. You're training it daily.",
  "Weeks of effort. A lifetime of clarity.",
  "The algorithm stops here. You are in control.",
  "42 days. A new you. Keep your streak alive.",
  "Routine beats motivation. You've found yours.",
  "Every day offline is a day fully lived.",
  "Mental clarity isn't found in a feed. It's earned.",
  "Stand firm. The urge to scroll will pass.",
  "Progress, not perfection. Keep checking in.",
  "You've come too far to turn back now.",
  "Almost there. The best version of you is waiting.",
  "Last stretch. Finish what you started.",
  "42 days complete. Legend. Now make it a lifestyle.",
];

const List<String> _weeklyBadges = [
  '🌱 Week 1: Seedling', // Week 1 complete
  '🔥 Week 2: Ignited', // Week 2 complete
  '💪 Week 3: Resilient', // Week 3 complete
  '🧠 Week 4: Focused', // Week 4 complete
  '🦅 Week 5: Free Mind', // Week 5 complete
  '🏆 Week 6: Champion', // Week 6 complete
];

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  final HiveStorage _storage = HiveStorage();
  int _challengeDay = 1;
  bool _isCheckedInToday = false;
  List<String> _checkInList = [];
  bool _showConfetti = false;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
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
    _loadChallengeData();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadChallengeData() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    String? startStr =
        _storage.getSetting('challenge_start_date', null) as String?;
    if (startStr == null) {
      startStr = now.toIso8601String();
      _storage.saveSetting('challenge_start_date', startStr);
    }
    final startDate = DateTime.parse(startStr);
    final diffDays = now.difference(startDate).inDays + 1;
    _challengeDay = diffDays.clamp(1, 42);

    final List<dynamic> checkIns =
        _storage.getSetting('challenge_check_ins', []) as List<dynamic>;
    _checkInList = checkIns.map((e) => e.toString()).toList();
    _isCheckedInToday = _checkInList.contains(todayStr);

    if (mounted) setState(() {});
  }

  // ── Correct streak calculation ──────────────────────────────────────
  int _calculateStreak() {
    if (_checkInList.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    DateTime cursor = DateTime(now.year, now.month, now.day);

    // If checked in today, start from today; otherwise start from yesterday
    final todayStr = '${cursor.year}-${cursor.month}-${cursor.day}';
    if (!_checkInList.contains(todayStr)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (true) {
      final s = '${cursor.year}-${cursor.month}-${cursor.day}';
      if (_checkInList.contains(s)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Completed weeks ────────────────────────────────────────────────
  int get _completedWeeks {
    int completed = 0;
    final now = DateTime.now();
    final startStr = _storage.getSetting('challenge_start_date', now.toIso8601String()) as String;
    final startDate = DateTime.parse(startStr);
    final startLocalDate = DateTime(startDate.year, startDate.month, startDate.day);
    for (int w = 0; w < 6; w++) {
      bool weekCompleted = true;
      for (int d = 1; d <= 7; d++) {
        final dayNum = w * 7 + d;
        final targetDate = startLocalDate.add(Duration(days: dayNum - 1));
        final targetStr = '${targetDate.year}-${targetDate.month}-${targetDate.day}';
        if (!_checkInList.contains(targetStr)) {
          weekCompleted = false;
          break;
        }
      }
      if (weekCompleted) {
        completed++;
      }
    }
    return completed;
  }

  // ── Daily motivational quote (changes each day) ───────────────────
  String get _todayQuote {
    final dayIndex = (_challengeDay - 1).clamp(0, _motivationalQuotes.length - 1);
    return _motivationalQuotes[dayIndex];
  }

  void _checkIn() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    _toggleCheckIn(todayStr, _challengeDay);
  }

  void _toggleCheckIn(String dateStr, int dayNum) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_checkInList.contains(dateStr)) {
        _checkInList.remove(dateStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed check-in for Day $dayNum'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _checkInList.add(dateStr);
        _showConfetti = true;
        _confettiController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Day $dayNum checked in! Streak: ${_calculateStreak()} 🔥'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: challengeColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _storage.saveSetting('challenge_check_ins', _checkInList);

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      _isCheckedInToday = _checkInList.contains(todayStr);
    });
  }

  void _resetChallenge() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Challenge?'),
        content: const Text(
            'This will delete all check-in history and start the 6-Week Challenge from Day 1.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Reset'),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _storage.saveSetting(
                  'challenge_start_date', DateTime.now().toIso8601String());
              _storage.saveSetting('challenge_check_ins', <String>[]);
              Navigator.pop(context);
              _loadChallengeData();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
    final completionPercent = (_checkInList.length / 42.0).clamp(0.0, 1.0);
    final streak = _calculateStreak();

    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Header ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge',
                            style: headingStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: challengeColor),
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 4),
                          Text(
                            'Reclaim your attention span',
                            style: bodyStyle(color: textMid, fontSize: 14),
                          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                        ],
                      ),
                      IconButton(
                        icon: Icon(CupertinoIcons.arrow_counterclockwise,
                            color: textMid, size: 24),
                        onPressed: _resetChallenge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Scrollable content ────────────────────────────────
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [

                        // ── Main stats card ────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                challengeColor.withOpacity(0.16),
                                primary.withOpacity(0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(
                              color: challengeColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Top row: week + circular progress
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Week ${((_challengeDay - 1) / 7).floor() + 1} of 6',
                                        style: headingStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: challengeColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Day $_challengeDay of 42',
                                        style: bodyStyle(
                                            color: textDark.withOpacity(0.7),
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 72,
                                        height: 72,
                                        child: CircularProgressIndicator(
                                          value: completionPercent,
                                          strokeWidth: 6,
                                          backgroundColor:
                                              challengeColor.withOpacity(0.1),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  challengeColor),
                                        ),
                                      ),
                                      Text(
                                        '${(completionPercent * 100).round()}%',
                                        style: headingStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 28),
                              // Stat counters
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _StatBox(
                                      label: 'Completed',
                                      value: '${_checkInList.length}',
                                      color: challengeColor),
                                  _StatBox(
                                      label: 'Remaining',
                                      value:
                                          '${42 - _checkInList.length}',
                                      color: textMid),
                                  _StatBox(
                                      label: 'Streak 🔥',
                                      value: '$streak days',
                                      color: Colors.orangeAccent),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 16),

                        // ── Today's motivational quote ─────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: surface.withOpacity(isDarkMode ? 0.45 : 0.9),
                            borderRadius: BorderRadius.circular(cardRadius),
                            border: Border.all(
                                color: textDark.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              Text('💬',
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _todayQuote,
                                  style: bodyStyle(
                                      color: textDark.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 450.ms, delay: 100.ms),

                        const SizedBox(height: 16),

                        // ── Weekly milestone badges ─────────────────────
                        if (_completedWeeks > 0) ...[
                          Text(
                            'Milestones 🏅',
                            style: headingStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _completedWeeks,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color:
                                      challengeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color:
                                          challengeColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _weeklyBadges[i],
                                  style: bodyStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: challengeColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Check in button ─────────────────────────────
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _isCheckedInToday ? null : _checkIn,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _isCheckedInToday
                                  ? Colors.grey.withOpacity(0.25)
                                  : challengeColor,
                              borderRadius:
                                  BorderRadius.circular(buttonRadius),
                              boxShadow: _isCheckedInToday
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: challengeColor
                                            .withOpacity(0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _isCheckedInToday
                                  ? '✅ Checked in for Today'
                                  : '🔥 Check In Today',
                              style: bodyStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                        const SizedBox(height: 28),

                        // ── 6-Week grid with week labels ─────────────────
                        Text(
                          'Your 6-Week Path',
                          style: headingStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        ...List.generate(6, (weekIndex) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Week label
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      'Week ${weekIndex + 1}',
                                      style: bodyStyle(
                                          color: _completedWeeks > weekIndex
                                              ? challengeColor
                                              : textMid,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_completedWeeks > weekIndex)
                                      Text(
                                        _weeklyBadges[weekIndex]
                                            .split(' ')
                                            .first,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        margin: const EdgeInsets.only(left: 8),
                                        color: textDark.withOpacity(0.06),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 7-day row for this week
                              Row(
                                children: List.generate(7, (dayInWeek) {
                                  final dayNum =
                                      weekIndex * 7 + dayInWeek + 1;
                                  final isCurrent =
                                      dayNum == _challengeDay;
                                  // Check if this calendar day was completed
                                  final now = DateTime.now();
                                  final startStr = _storage.getSetting('challenge_start_date', now.toIso8601String()) as String;
                                  final startDate = DateTime.parse(startStr);
                                  final startLocalDate = DateTime(startDate.year, startDate.month, startDate.day);
                                  final targetDate = startLocalDate.add(
                                      Duration(days: dayNum - 1));
                                  final targetStr =
                                      '${targetDate.year}-${targetDate.month}-${targetDate.day}';
                                  
                                  final isCompleted = _checkInList.contains(targetStr);
                                  final todayLocalDate = DateTime(now.year, now.month, now.day);
                                  final isPast = targetDate.isBefore(todayLocalDate);
                                  final isFuture = targetDate.isAfter(todayLocalDate);

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (isFuture) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("You cannot check in for future days!"),
                                              behavior: SnackBarBehavior.floating,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                          return;
                                        }
                                        _toggleCheckIn(targetStr, dayNum);
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.only(
                                            right: 6, bottom: 6),
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? challengeColor.withOpacity(0.28)
                                              : isCurrent
                                                  ? primary.withOpacity(0.15)
                                                  : isPast
                                                      ? Colors.red.withOpacity(0.05)
                                                      : surface.withOpacity(
                                                          isDarkMode ? 0.3 : 0.75),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isCurrent
                                                ? primary
                                                : isCompleted
                                                    ? challengeColor
                                                        .withOpacity(0.5)
                                                    : isPast
                                                        ? Colors.red.withOpacity(0.2)
                                                        : textDark.withOpacity(
                                                            0.07),
                                            width: isCurrent ? 2 : 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: isCompleted
                                            ? Icon(CupertinoIcons.checkmark,
                                                size: 12,
                                                color: challengeColor)
                                            : isPast
                                                ? Text(
                                                    '$dayNum',
                                                    style: bodyStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w400,
                                                        color: Colors.red.withOpacity(0.5),
                                                    ).copyWith(decoration: TextDecoration.lineThrough),
                                                  )
                                                : Text(
                                                    '$dayNum',
                                                    style: bodyStyle(
                                                        fontSize: 11,
                                                        fontWeight: isCurrent
                                                            ? FontWeight.bold
                                                            : FontWeight.w400,
                                                        color: isCurrent
                                                            ? primary
                                                            : textDark.withOpacity(
                                                                0.5)),
                                                  ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Confetti overlay on check-in ────────────────────────────
          if (_showConfetti)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                          _confettiController.value, _challengeDay),
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
}

// ── Stat box sub-widget ────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: headingStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: bodyStyle(color: textMid, fontSize: 12)),
      ],
    );
  }
}

// ── Confetti painter ───────────────────────────────────────────────────
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

      paint.color = _colors[i % _colors.length].withOpacity(opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotate);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero,
              width: particleSize,
              height: particleSize * 0.45),
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
