import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../themes/app_theme.dart';
import '../widgets/ambient_background.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _handleTabTap(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTabIndex = index;
    });

    if (index == 4) {
      _openSettings();
    } else if (index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tab $index tapped!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bgLight,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Content area with top padding for the floating top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildEmptyState(),
              ),

              // Floating Top Header (Apple-style glassmorphic)
              Positioned(
                top: 10,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: surface.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: textDark.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.search,
                                  color: textMid,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: _searchController,
                                    placeholder: 'Search...',
                                    placeholderStyle: bodyStyle(
                                      color: textDark.withValues(alpha: 0.4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    style: bodyStyle(
                                      color: textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    decoration: null,
                                    cursorColor: primary,
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        color: textDark.withValues(alpha: 0.4),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: surface.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.bell,
                              color: textDark,
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Bottom Navigation Bar (Apple-style glassmorphic)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      height: 66,
                      decoration: BoxDecoration(
                        color: surface.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: textDark.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavBarItem(0, CupertinoIcons.home),
                          _buildNavBarItem(1, CupertinoIcons.compass),
                          _buildNavBarItem(2, CupertinoIcons.add),
                          _buildNavBarItem(3, CupertinoIcons.heart),
                          _buildNavBarItem(4, CupertinoIcons.settings),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _handleTabTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? (isDarkMode ? Colors.white : const Color(0xFF1C1C1E)) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          icon,
          color: isSelected ? (isDarkMode ? const Color(0xFF121212) : Colors.white) : textDark.withValues(alpha: 0.4),
          size: index == 2 ? 28 : 23,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.rocket_fill,
            color: primary.withValues(alpha: 0.8),
            size: 80,
          ).animate().slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
          const SizedBox(height: 24),
          Text(
            'Welcome to Starter Kit',
            style: headingStyle(fontSize: 24, color: textDark),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Text(
            'Your new Flutter app is ready.\nStart building something amazing!',
            textAlign: TextAlign.center,
            style: bodyStyle(color: textMid, fontSize: 16, height: 1.5),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }
}
