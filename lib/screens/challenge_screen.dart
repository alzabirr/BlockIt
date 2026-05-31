import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../storage/hive_storage.dart';
import '../themes/app_theme.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final HiveStorage _storage = HiveStorage();
  int _challengeDay = 1;
  bool _isCheckedInToday = false;
  List<String> _checkInList = [];

  @override
  void initState() {
    super.initState();
    _loadChallengeData();
  }

  void _loadChallengeData() {
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
    _checkInList = checkIns.map((e) => e.toString()).toList();
    _isCheckedInToday = _checkInList.contains(todayStr);
    
    setState(() {});
  }

  void _checkIn() {
    HapticFeedback.heavyImpact();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    
    if (!_checkInList.contains(todayStr)) {
      _checkInList.add(todayStr);
      _storage.saveSetting('challenge_check_ins', _checkInList);
      setState(() {
        _isCheckedInToday = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Awesome! Checked in for Day $_challengeDay of NoScroll Challenge!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: accent,
        ),
      );
    }
  }

  void _resetChallenge() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Challenge?'),
        content: const Text('This will delete all check-in history and start the 6-Week Challenge from Day 1.'),
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
              _storage.saveSetting('challenge_start_date', DateTime.now().toIso8601String());
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
    final completionPercent = (_checkInList.length / 42.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenge',
                        style: headingStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Reclaim your attention span',
                        style: bodyStyle(color: textMid, fontSize: 14),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.arrow_counterclockwise, color: textMid, size: 28),
                    onPressed: _resetChallenge,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Premium Stats Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withOpacity(0.18), primary.withOpacity(0.08)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(cardRadius),
                        border: Border.all(
                          color: accent.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week ${((_challengeDay - 1) / 7).floor() + 1}',
                                    style: headingStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accent),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Day $_challengeDay of 42',
                                    style: bodyStyle(color: textDark.withOpacity(0.8), fontSize: 14),
                                  ),
                                ],
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CircularProgressIndicator(
                                      value: completionPercent,
                                      strokeWidth: 6,
                                      backgroundColor: accent.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                                    ),
                                  ),
                                  Text(
                                    '${(completionPercent * 100).round()}%',
                                    style: headingStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text('${_checkInList.length}', style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('Completed', style: bodyStyle(color: textMid, fontSize: 12)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('${42 - _checkInList.length}', style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('Remaining', style: bodyStyle(color: textMid, fontSize: 12)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text('${_checkInList.isNotEmpty ? 1 : 0} days', style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('Streak', style: bodyStyle(color: textMid, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),

                    // Daily Check In Button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isCheckedInToday ? null : _checkIn,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isCheckedInToday ? Colors.grey.withOpacity(0.3) : accent,
                          borderRadius: BorderRadius.circular(buttonRadius),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isCheckedInToday ? 'Checked in for Today' : 'Check In Today',
                          style: bodyStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Your 6-Week Path',
                      style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Grid or List of Weeks progress
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 42,
                      itemBuilder: (context, index) {
                        final dayNum = index + 1;
                        final isCompleted = _checkInList.any((e) {
                          // Match check-in dates
                          final now = DateTime.now();
                          final startDate = now.subtract(Duration(days: _challengeDay - 1));
                          final targetDate = startDate.add(Duration(days: index));
                          final targetStr = "${targetDate.year}-${targetDate.month}-${targetDate.day}";
                          return _checkInList.contains(targetStr);
                        }) || dayNum < _challengeDay; // Placeholder check-in visualization

                        final isCurrent = dayNum == _challengeDay;

                        return Container(
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? accent.withOpacity(0.3)
                                : isCurrent
                                    ? primary.withOpacity(0.2)
                                    : surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? primary
                                  : isCompleted
                                      ? accent.withOpacity(0.5)
                                      : textDark.withOpacity(0.08),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: bodyStyle(
                              fontWeight: isCurrent || isCompleted ? FontWeight.bold : FontWeight.w300,
                              color: isCurrent
                                  ? primary
                                  : isCompleted
                                      ? accent
                                      : textDark.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
