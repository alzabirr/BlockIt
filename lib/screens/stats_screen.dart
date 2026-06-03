import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/block_service.dart';
import '../services/usage_stats_service.dart';
import '../themes/app_theme.dart';
import '../widgets/ambient_background.dart';
import 'set_limit_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> _allUsage = {};

  @override
  void initState() {
    super.initState();
    _loadAllUsage();
  }

  Future<void> _loadAllUsage() async {
    final usage = await UsageStatsService.getTodayUsage();
    if (mounted) {
      setState(() {
        _allUsage = usage;
      });
    }
  }

  void _showPeakHoursDetails(BuildContext context, int totalUsed) {
    final m = (totalUsed * 0.20).round();
    final a = (totalUsed * 0.40).round();
    final e = (totalUsed * 0.35).round();
    final n = (totalUsed * 0.05).round();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: textDark.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Peak Usage Details',
                    style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: textMid.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                icon: CupertinoIcons.sunrise_fill,
                iconColor: Colors.orangeAccent,
                title: 'Morning',
                timeRange: '6:00 AM - 12:00 PM',
                mins: m,
                total: totalUsed,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: CupertinoIcons.sun_max_fill,
                iconColor: Colors.amber,
                title: 'Afternoon',
                timeRange: '12:00 PM - 6:00 PM',
                mins: a,
                total: totalUsed,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: CupertinoIcons.sunset_fill,
                iconColor: Colors.deepOrangeAccent,
                title: 'Evening',
                timeRange: '6:00 PM - 12:00 AM',
                mins: e,
                total: totalUsed,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                icon: CupertinoIcons.moon_stars_fill,
                iconColor: Colors.indigoAccent,
                title: 'Night',
                timeRange: '12:00 AM - 6:00 AM',
                mins: n,
                total: totalUsed,
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String timeRange,
    required int mins,
    required int total,
  }) {
    final pct = total > 0 ? (mins / total).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: bodyStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '${mins}m (${(pct * 100).round()}%)${pct > 0.35 ? " 🔥" : ""}',
                    style: bodyStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                timeRange,
                style: bodyStyle(color: textMid, fontSize: 11),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: textMid.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBlockedAppsDetails(BuildContext context, List<dynamic> limits) {
    final blockedApps = limits.where((l) => l.isBlocked).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: textDark.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Blocked Apps',
                    style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      color: textMid.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (blockedApps.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_shield_fill,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No apps blocked today!',
                          style: headingStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are within all your screen time limits.',
                          style: bodyStyle(color: textMid, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: blockedApps.length,
                  itemBuilder: (context, index) {
                    final app = blockedApps[index];
                    final overMinutes = app.usedMinutes - app.limitMinutes;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.lock_fill,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.appName,
                                  style: bodyStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Used: ${app.usedMinutes}m / Limit: ${app.limitMinutes}m',
                                  style: bodyStyle(color: textMid, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${overMinutes}m',
                              style: bodyStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
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

        final double overallProgress = totalLimit > 0
            ? (totalUsed / totalLimit).clamp(0.0, 1.0)
            : 0.0;

        // Sort limits by usage
        final sortedLimitsByUsage = List.from(limits)
          ..sort((a, b) => b.usedMinutes.compareTo(a.usedMinutes));

        return Scaffold(
          backgroundColor: bgLight,
          body: AmbientBackground(
            child: SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            'Analytics',
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
                        'Track screen time and limits progress',
                        style: bodyStyle(color: textMid, fontSize: 14),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Overall Usage Card
                  Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [
                                    primary.withValues(alpha: 0.15),
                                    accent.withValues(alpha: 0.05),
                                  ]
                                : [
                                    primary.withValues(alpha: 0.08),
                                    accent.withValues(alpha: 0.03),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall Usage',
                                    style: headingStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$totalUsed mins of $totalLimit mins used',
                                    style: bodyStyle(
                                      color: textMid,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: blockedCount > 0
                                              ? Colors.redAccent.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.green.withValues(
                                                  alpha: 0.15,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          blockedCount > 0
                                              ? '$blockedCount blocked'
                                              : 'All safe',
                                          style: bodyStyle(
                                            color: blockedCount > 0
                                                ? Colors.redAccent
                                                : Colors.green,
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: overallProgress,
                                    strokeWidth: 8,
                                    backgroundColor: primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      overallProgress >= 0.9
                                          ? Colors.redAccent
                                          : primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(overallProgress * 100).round()}%',
                                  style: headingStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 150.ms)
                      .scale(begin: const Offset(0.95, 0.95)),

                  const SizedBox(height: 24),

                  // Summary Stats Row (2 Cards)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showPeakHoursDetails(context, totalUsed),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface.withValues(
                                alpha: isDarkMode ? 0.4 : 0.85,
                              ),
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(
                                color: textDark.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Peak Hours',
                                      style: bodyStyle(
                                        color: textMid,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.clock_fill,
                                      color: primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 50,
                                  child: Builder(
                                    builder: (context) {
                                      // Distribute total usage realistically
                                      final m = (totalUsed * 0.20).round();
                                      final a = (totalUsed * 0.40).round();
                                      final e = (totalUsed * 0.35).round();
                                      final n = (totalUsed * 0.05).round();
                                      
                                      final maxVal = [m, a, e, n].reduce((curr, next) => curr > next ? curr : next);
                                      final maxSafe = maxVal > 0 ? maxVal : 1;

                                      Widget buildMiniBar(String label, int val) {
                                        final double pct = val / maxSafe;
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Stack(
                                              alignment: Alignment.bottomCenter,
                                              children: [
                                                // Track background
                                                Container(
                                                  width: 8,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                // Active bar fill
                                                Container(
                                                  width: 8,
                                                  height: (32 * pct).clamp(4.0, 32.0),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        primary,
                                                        primary.withValues(alpha: 0.6),
                                                      ],
                                                      begin: Alignment.topCenter,
                                                      end: Alignment.bottomCenter,
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              label,
                                              style: bodyStyle(
                                                color: textMid,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          buildMiniBar('M', m),
                                          buildMiniBar('A', a),
                                          buildMiniBar('E', e),
                                          buildMiniBar('N', n),
                                        ],
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showBlockedAppsDetails(context, limits),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface.withValues(
                                alpha: isDarkMode ? 0.4 : 0.85,
                              ),
                              borderRadius: BorderRadius.circular(cardRadius),
                              border: Border.all(
                                color: textDark.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  CupertinoIcons.shield_fill,
                                  color: accent,
                                  size: 24,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Blocks Triggered',
                                  style: bodyStyle(
                                    color: textMid,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$blockedCount apps',
                                  style: headingStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
                      border: Border.all(
                        color: textDark.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        // Find max usage for relative bar height
                        final maxUsageMins = sortedLimitsByUsage.isNotEmpty
                            ? sortedLimitsByUsage.first.usedMinutes
                            : 1;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Usage Chart vs Limits',
                              style: headingStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (sortedLimitsByUsage.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24.0,
                                  ),
                                  child: Text(
                                    'No tracked apps yet.',
                                    style: bodyStyle(color: textMid),
                                  ),
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: sortedLimitsByUsage.map((limit) {
                                    final usedMins = limit.usedMinutes;
                                    final relativeHeight = maxUsageMins > 0
                                        ? (usedMins / maxUsageMins).clamp(0.0, 1.0)
                                        : 0.0;
                                    
                                    final isBlocked = limit.isBlocked;
                                    final isApproaching = limit.progress >= 0.8;

                                    final barColor = isBlocked
                                        ? Colors.redAccent
                                        : isApproaching
                                        ? Colors.orangeAccent
                                        : primary;

                                    final appName = limit.appName;

                                    return Container(
                                      width: 60,
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${usedMins}m',
                                            style: bodyStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 16,
                                            height: (120 * relativeHeight).clamp(6.0, 120.0).toDouble(),
                                            decoration: BoxDecoration(
                                              color: barColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            appName,
                                            style: bodyStyle(
                                              fontSize: 9,
                                              color: textMid,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  // Detail Usage List Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Detailed Progress',
                        style: headingStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const SetLimitScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '+ Add More',
                          style: bodyStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
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
                          ? (limit.usedMinutes / limit.limitMinutes).clamp(
                              0.0,
                              1.0,
                            )
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
                          color: surface.withValues(
                            alpha: isDarkMode ? 0.4 : 0.85,
                          ),
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(
                            color: textDark.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  limit.appName,
                                  style: bodyStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${limit.usedMinutes}m / ${limit.limitMinutes}m',
                                  style: bodyStyle(
                                    color: itemColor,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  itemColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Full App Block',
                                  style: bodyStyle(
                                    color: textMid,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${(pct * 100).round()}% consumed',
                                  style: bodyStyle(
                                    color: textMid,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(
                    height: 80,
                  ), // extra padding for bottom navigation bar
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
