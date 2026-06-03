import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:provider/provider.dart';
import '../services/block_service.dart';
import '../themes/app_theme.dart';

class SetLimitScreen extends StatefulWidget {
  const SetLimitScreen({super.key});

  @override
  State<SetLimitScreen> createState() => _SetLimitScreenState();
}

class _SetLimitScreenState extends State<SetLimitScreen> {
  List<AppInfo> _apps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledApps() async {
    try {
      // Get all apps (including system apps like YouTube, Chrome, etc)
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );

      // Filter out internal non-user-facing system packages to keep the list clean
      final userFacingApps = apps.where((app) {
        final pkg = app.packageName.toLowerCase();
        
        // Explicitly allow well-known user-facing pre-installed Google/System apps
        if (pkg.contains('youtube') || 
            pkg.contains('chrome') || 
            pkg.contains('maps') || 
            pkg.contains('gallery') ||
            pkg.contains('camera') ||
            pkg.contains('browser') ||
            pkg.contains('vending') || // Google Play Store
            pkg.contains('com.google.android.gm') || // Gmail
            pkg.contains('com.google.android.apps.photos')) { // Photos
          return true;
        }

        // Filter out core system processes and background services
        if (pkg == 'android' ||
            pkg.startsWith('com.android.providers.') ||
            pkg.startsWith('com.android.systemui') ||
            pkg.startsWith('com.android.inputmethod.') ||
            pkg.startsWith('com.google.android.inputmethod.') ||
            pkg.startsWith('com.android.server.') ||
            pkg.startsWith('com.android.kernel') ||
            pkg.startsWith('com.google.android.overlay') ||
            pkg.startsWith('com.google.android.ext.services') ||
            pkg.startsWith('com.google.android.packageinstaller') ||
            pkg.contains('telephony') ||
            pkg.contains('bluetooth') ||
            pkg.contains('keychain') ||
            pkg.contains('wallpaper')) {
          return false;
        }
        return true;
      }).toList();

      // Sort alphabetically
      userFacingApps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      if (mounted) {
        setState(() {
          _apps = userFacingApps;
          _filteredApps = userFacingApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading apps: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredApps = _apps;
      } else {
        _filteredApps = _apps
            .where((app) =>
                app.name.toLowerCase().contains(query.toLowerCase()) ||
                app.packageName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showLimitSliderBottomSheet(AppInfo app) {
    HapticFeedback.mediumImpact();
    // Check if there is already a limit set
    final blockService = context.read<BlockService>();
    final existingLimitIndex = blockService.limits.indexWhere((l) => l.packageName == app.packageName);
    
    double initialLimitMinutes = 60.0;
    String currentAction = 'exit_app';

    if (existingLimitIndex >= 0) {
      final existing = blockService.limits[existingLimitIndex];
      initialLimitMinutes = existing.limitMinutes.toDouble();
      currentAction = existing.actionType;
    }

    double sliderValue = initialLimitMinutes;

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
                        if (app.icon != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              app.icon!,
                              width: 64,
                              height: 64,
                            ),
                          )
                        else
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(CupertinoIcons.app_fill, color: primary, size: 32),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          app.name,
                          style: headingStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.packageName,
                          style: bodyStyle(color: textMid, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        
                        // 1. Time Slider
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

                        // 2. Action Type dropdown
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

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: textDark.withValues(alpha: 0.2)),
                                    borderRadius: BorderRadius.circular(buttonRadius),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Cancel',
                                    style: bodyStyle(fontWeight: FontWeight.w600),
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
                                    app.packageName,
                                    app.name,
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
                                      content: Text('Limit set for ${app.name}'),
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
                                    'Set Limit',
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
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(radius: 15),
                          const SizedBox(height: 16),
                          Text('Scanning installed apps...', style: bodyStyle(color: textMid)),
                        ],
                      ),
                    )
                  : _filteredApps.isEmpty
                      ? Center(
                          child: Text('No apps found', style: bodyStyle(color: textMid, fontSize: 16)),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40, top: 10),
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: surface.withValues(alpha: isDarkMode ? 0.4 : 0.8),
                                borderRadius: BorderRadius.circular(cardRadius),
                                border: Border.all(
                                  color: textDark.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: app.icon != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          app.icon!,
                                          width: 45,
                                          height: 45,
                                        ),
                                      )
                                    : Container(
                                        width: 45,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(CupertinoIcons.app_fill, color: primary, size: 24),
                                      ),
                                title: Text(
                                  app.name,
                                  style: bodyStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    app.packageName,
                                    style: bodyStyle(color: textMid, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                trailing: Icon(
                                  CupertinoIcons.chevron_forward,
                                  color: textMid.withValues(alpha: 0.5),
                                  size: 16,
                                ),
                                onTap: () => _showLimitSliderBottomSheet(app),
                              ),
                            ).animate().fadeIn(duration: 300.ms, delay: (index * 20).ms).slideY(begin: 0.1, end: 0);
                          },
                        ),
            ),

            // Top Glassmorphic search and back bar
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipRRect(
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
                                color: textDark.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.back,
                                color: textDark,
                                size: 23,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
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
                                  placeholder: 'Search app...',
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
                                  onChanged: _filterApps,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _filterApps('');
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
