import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'set_limit_screen.dart';
import 'challenge_screen.dart';
import 'settings_screen.dart';
import '../themes/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const SetLimitScreen(),   // Index 2 (Center)
    const ChallengeScreen(), // Index 3
    const SettingsScreen(),  // Index 4
  ];

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // Screen content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating Glassmorphic Bottom Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: surface.withOpacity(isDarkMode ? 0.6 : 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: textDark.withOpacity(0.08),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, CupertinoIcons.house_fill, 'Home'),
                      _buildNavItem(1, CupertinoIcons.chart_bar_fill, 'Stats'),
                      _buildNavItem(2, CupertinoIcons.plus_circle_fill, 'Add Limit'),
                      _buildNavItem(3, CupertinoIcons.flame_fill, 'Challenge'),
                      _buildNavItem(4, CupertinoIcons.gear_solid, 'Settings'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    // Index 3 is Challenge (red challengeColor), others are primary
    final activeColor = index == 3 ? challengeColor : primary;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            index == 3
                ? FlameIconWithParticles(
                    isSelected: isSelected,
                    activeColor: activeColor,
                  )
                : Icon(
                    icon,
                    color: isSelected ? activeColor : textMid.withOpacity(0.6),
                    size: 22,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: bodyStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : textMid.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class FlameIconWithParticles extends StatefulWidget {
  final bool isSelected;
  final Color activeColor;

  const FlameIconWithParticles({
    super.key,
    required this.isSelected,
    required this.activeColor,
  });

  @override
  State<FlameIconWithParticles> createState() => _FlameIconWithParticlesState();
}

class _FlameIconWithParticlesState extends State<FlameIconWithParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FireParticle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(_updateParticles);

    if (widget.isSelected) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(FlameIconWithParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.repeat();
      // Spawn a massive burst of particles on click
      for (int i = 0; i < 25; i++) {
        _spawnParticle(isBurst: true);
      }
    } else if (!widget.isSelected) {
      _controller.stop();
      _particles.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spawnParticle({bool isBurst = false}) {
    _particles.add(
      _FireParticle(
        x: 25.0 + (_random.nextDouble() - 0.5) * 8.0, // tighter spawn
        y: isBurst ? (20.0 + _random.nextDouble() * 25.0) : 46.0,
        vx: (_random.nextDouble() - 0.5) * 0.8, // gentler drift
        vy: -0.5 - _random.nextDouble() * 0.8, // slower, smoother rise
        life: 1.0,
        decay: 0.015 + _random.nextDouble() * 0.02, // lives longer for fluid look
        size: 2.5 + _random.nextDouble() * 3.5, // slightly smaller to blend beautifully
      ),
    );
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (var p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= p.decay;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // Continually spawn new fire embers smoothly
      if (widget.isSelected && _random.nextDouble() < 0.65) {
        _spawnParticle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Fire particles painted above/behind the flame icon
        Positioned(
          bottom: 4, // positioned exactly relative to icon height
          child: CustomPaint(
            size: const Size(50, 50),
            painter: _FireParticlePainter(_particles),
          ),
        ),
        // The flame icon itself
        Icon(
          CupertinoIcons.flame_fill,
          color: widget.isSelected ? widget.activeColor : textMid.withOpacity(0.6),
          size: 22,
        ),
      ],
    );
  }
}

class _FireParticle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double decay;
  double size;

  _FireParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.decay,
    required this.size,
  });
}

class _FireParticlePainter extends CustomPainter {
  final List<_FireParticle> particles;

  _FireParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8); // Glowing fire blur

    for (var p in particles) {
      final colorVal = p.life;
      Color pColor;
      if (colorVal > 0.6) {
        // Hottest inner core: bright cream-yellow
        pColor = const Color(0xFFFFFDD0).withOpacity(p.life);
      } else if (colorVal > 0.3) {
        // Flame color: hot orange-yellow
        pColor = Colors.orangeAccent.withOpacity(p.life);
      } else {
        // Outer glow: deep fire red
        pColor = const Color(0xFFFF3B30).withOpacity(p.life);
      }

      paint.color = pColor;
      canvas.drawCircle(Offset(p.x, p.y), p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireParticlePainter oldDelegate) => true;
}
