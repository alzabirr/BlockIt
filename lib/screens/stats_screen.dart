import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/block_service.dart';
import '../themes/app_theme.dart';
import '../widgets/ambient_background.dart';
import 'set_limit_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
    final blockService = Provider.of<BlockService>(context);
    final limits = blockService.limits;

    // Calculations
    int totalLimit = 0;
    int totalUsed = 0;
    int blockedCount = 0;

    for (var l in limits) {
      totalLimit += l.limitMinutes;
      totalUsed += l.usedMinutes;
      if (l.isBlocked) blockedCount++;
    }

    final double overallProgress = totalLimit > 0 ? (totalUsed / totalLimit).clamp(0.0, 1.0) : 0.0;
    
    // Sort limits by usage
    final sortedLimitsByUsage = List.from(limits)..sort((a, b) => b.usedMinutes.compareTo(a.usedMinutes));

    return Scaffold(
      backgroundColor: bgLight,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: headingStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    'Track screen time and limits progress',
                    style: bodyStyle(color: textMid, fontSize: 14),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Stats Row (2 Cards)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface.withValues(alpha: isDarkMode ? 0.4 : 0.85),
                        borderRadius: BorderRadius.circular(cardRadius),
                        border: Border.all(color: textDark.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(CupertinoIcons.hourglass, color: primary, size: 24),
                          const SizedBox(height: 12),
                          Text('Total Usage', style: bodyStyle(color: textMid, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$totalUsed mins', style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface.withValues(alpha: isDarkMode ? 0.4 : 0.85),
                        borderRadius: BorderRadius.circular(cardRadius),
                        border: Border.all(color: textDark.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(CupertinoIcons.shield_fill, color: accent, size: 24),
                          const SizedBox(height: 12),
                          Text('Blocks Triggered', style: bodyStyle(color: textMid, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$blockedCount apps', style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 450.ms, delay: 150.ms),

              const SizedBox(height: 24),

              // Usage Bar Chart Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: isDarkMode ? 0.45 : 0.9),
                  borderRadius: BorderRadius.circular(cardRadius),
                  border: Border.all(color: textDark.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage Chart vs Limits',
                      style: headingStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (limits.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'No apps set for tracking yet.',
                            style: bodyStyle(color: textMid),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 160,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: limits.take(5).map((limit) {
                            final double pct = limit.limitMinutes > 0
                                ? (limit.usedMinutes / limit.limitMinutes).clamp(0.0, 1.0)
                                : 0.0;
                            final barColor = limit.isBlocked
                                ? Colors.redAccent
                                : pct >= 0.8
                                    ? Colors.orangeAccent
                                    : primary;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${limit.usedMinutes}m',
                                    style: bodyStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  // The actual visual bar
                                  Container(
                                    width: 16,
                                    height: (100 * pct).clamp(6.0, 100.0),
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    limit.appName,
                                    style: bodyStyle(fontSize: 10, color: textMid, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

              const SizedBox(height: 24),

              // Detail Usage List Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detailed Progress',
                    style: headingStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const SetLimitScreen()),
                      );
                    },
                    child: Text(
                      '+ Add More',
                      style: bodyStyle(color: primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (limits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                  child: Text(
                    'Add app limits to see detailed analytics.',
                    style: bodyStyle(color: textMid),
                  ),
                )
              else
                ...sortedLimitsByUsage.map((limit) {
                  final pct = limit.limitMinutes > 0
                      ? (limit.usedMinutes / limit.limitMinutes).clamp(0.0, 1.0)
                      : 0.0;
                  final itemColor = limit.isBlocked
                      ? Colors.redAccent
                      : pct >= 0.8
                          ? Colors.orangeAccent
                          : primary;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface.withValues(alpha: isDarkMode ? 0.4 : 0.85),
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: textDark.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              limit.appName,
                              style: bodyStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${limit.usedMinutes}m / ${limit.limitMinutes}m',
                              style: bodyStyle(color: itemColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: textMid.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(itemColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Full App Block',
                              style: bodyStyle(color: textMid, fontSize: 12),
                            ),
                            Text(
                              '${(pct * 100).round()}% consumed',
                              style: bodyStyle(color: textMid, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
              const SizedBox(height: 80), // extra padding for bottom navigation bar
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
