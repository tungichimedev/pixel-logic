import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'gallery_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _showOnboarding = false;
  bool _showTutorial = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    // Track session count for ad frequency
    final sessions = (prefs.getInt('session_count') ?? 0) + 1;
    await prefs.setInt('session_count', sessions);
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    final tutorialDone = prefs.getBool('tutorial_complete') ?? false;
    if (mounted) {
      setState(() {
        _showOnboarding = !onboardingDone;
        _showTutorial = onboardingDone && !tutorialDone;
        _loaded = true;
      });
    }
  }

  final _screens = const [
    HomeScreen(),
    GalleryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const GradientBackground(
          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () => setState(() {
          _showOnboarding = false;
          _showTutorial = true;
        }),
      );
    }

    if (_showTutorial) {
      return TutorialScreen(
        onComplete: () => setState(() => _showTutorial = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.85),
              border: const Border(
                top: BorderSide(color: Color(0x12FFFFFF)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.home_rounded, 'HOME'),
                    _navItem(1, Icons.grid_view_rounded, 'GALLERY'),
                    _navItem(2, Icons.settings_rounded, 'SETTINGS'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
