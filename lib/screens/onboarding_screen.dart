import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildWelcomePage(),
                    _buildHowItWorksPage(),
                    _buildGetStartedPage(),
                  ],
                ),
              ),
              // Page dots
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      width: i == _page ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.primary
                            : AppColors.textMuted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _page < 2
                    ? Row(
                        children: [
                          TextButton(
                            onPressed: _completeOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: const Text('Skip',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          const Spacer(),
                          _buildGoldButton(
                            label: 'NEXT',
                            onTap: () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: _buildGoldButton(
                          label: "LET'S PLAY!",
                          wide: true,
                          pixelFont: true,
                          onTap: _completeOnboarding,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldButton({
    required String label,
    required VoidCallback onTap,
    bool wide = false,
    bool pixelFont = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? 220 : null,
        height: 48,
        padding: wide ? null : const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: pixelFont
              ? AppFonts.pixel(
                  fontSize: 10,
                  color: const Color(0xFF1a0a00),
                  letterSpacing: 1,
                )
              : AppFonts.pixel(
                  fontSize: 9,
                  color: const Color(0xFF1a0a00),
                  letterSpacing: 1,
                ),
        ),
      ),
    );
  }

  // ─── PAGE 1: WELCOME ───

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Pixel heart grid
          _buildPixelHeart(),
          const SizedBox(height: 24),
          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF5CC),
                Color(0xFFFFE88A),
                Color(0xFFFFD84B),
                Color(0xFFFF9500),
              ],
            ).createShader(bounds),
            child: Text(
              'PIXEL LOGIC',
              style: AppFonts.pixel(
                  fontSize: 20, color: Colors.white, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'NONOGRAM PUZZLES',
            style: AppFonts.pixel(
                fontSize: 6, color: AppColors.textSecondary, letterSpacing: 3),
          ),
          const SizedBox(height: 32),
          // Tagline
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Solve clues. Fill cells.\n'),
                TextSpan(
                  text: 'Reveal pixel art.',
                  style: TextStyle(color: AppColors.satisfied),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildPixelHeart() {
    const filled = Color(0xFFFF4F7B);
    final pattern = [
      [false, true, false, true, false],
      [true, true, true, true, true],
      [true, true, true, true, true],
      [false, true, true, true, false],
      [false, false, true, false, false],
    ];
    return SizedBox(
      width: 140,
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pattern.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((isFilled) {
              return Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isFilled ? filled : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                              color: filled.withValues(alpha: 0.6),
                              blurRadius: 10)
                        ]
                      : null,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // ─── PAGE 2: HOW IT WORKS ───

  Widget _buildHowItWorksPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'HOW IT WORKS',
            style: AppFonts.pixel(
                fontSize: 10, color: AppColors.primary, letterSpacing: 2),
          ),
          const SizedBox(height: 20),
          // Step cards
          _buildStepCard(
            icon: Text('3',
                style: AppFonts.pixel(
                    fontSize: 14, color: AppColors.cellFilled)),
            title: 'Read the Clues',
            desc: 'Numbers tell you how many cells to fill in each row and column',
            color: AppColors.cellFilled,
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            icon: _buildMiniGrid(),
            title: 'Fill Cells',
            desc: 'Tap or drag to fill. Mark cells you know are empty',
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            icon: _buildColorMosaic(),
            title: 'Reveal Pixel Art',
            desc: 'Complete the puzzle to uncover colorful pixel art pictures',
            color: AppColors.satisfied,
          ),
          const Spacer(),
          // Before → After demo
          _buildBeforeAfterDemo(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required Widget icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGrid() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: AppColors.cellFilled,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 2),
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)))),
        const SizedBox(width: 2),
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)))),
      ],
    );
  }

  Widget _buildColorMosaic() {
    final colors = [
      const Color(0xFFFF4F7B),
      const Color(0xFF4488FF),
      const Color(0xFFFFD84B),
      const Color(0xFF00E676),
      const Color(0xFF9B59FF),
      const Color(0xFFFF4F7B),
      const Color(0xFF4488FF),
      const Color(0xFFFFD84B),
      const Color(0xFF00E676),
    ];
    return SizedBox(
      width: 34,
      height: 34,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: colors.map((c) {
          return Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBeforeAfterDemo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Before: empty grid with clues
        Column(
          children: [
            Text('CLUES',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            _buildEmptyGrid(),
          ],
        ),
        // Arrow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward_rounded,
              color: AppColors.primary, size: 24),
        ),
        // After: colored pixel art
        Column(
          children: [
            Text('REVEAL!',
                style: TextStyle(
                    color: AppColors.satisfied,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            _buildRevealGrid(),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyGrid() {
    return SizedBox(
      width: 85,
      height: 85,
      child: Column(
        children: List.generate(5, (r) {
          return Row(
            children: List.generate(5, (c) {
              return Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.all(0.5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildRevealGrid() {
    const pink = Color(0xFFFF4F7B);
    final heartPattern = [
      [false, true, false, true, false],
      [true, true, true, true, true],
      [true, true, true, true, true],
      [false, true, true, true, false],
      [false, false, true, false, false],
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: AppColors.satisfied.withValues(alpha: 0.15),
              blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 85,
          height: 85,
          child: Column(
            children: heartPattern.map((row) {
              return Row(
                children: row.map((filled) {
                  return Container(
                    width: 15,
                    height: 15,
                    margin: const EdgeInsets.all(0.5),
                    color: filled ? pink : Colors.transparent,
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── PAGE 3: GET STARTED ───

  Widget _buildGetStartedPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'WHAT YOU GET',
            style: AppFonts.pixel(
                fontSize: 10, color: AppColors.primary, letterSpacing: 2),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            emoji: '\u{1F3A8}',
            title: '30 Pixel Art Puzzles',
            desc: 'Animals and Space themed packs',
            color: AppColors.hearts,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            emoji: '\u26A1',
            title: 'New Puzzle Every Day',
            desc: 'Daily challenge with bonus XP',
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            emoji: '\u2B50',
            title: 'Earn Stars & Level Up',
            desc: 'Track your progress and achievements',
            color: AppColors.satisfied,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            emoji: '\u{1F5BC}',
            title: 'Build Your Collection',
            desc: 'Gallery of all your solved pixel art',
            color: AppColors.cellFilled,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            emoji: '\u2713',
            title: '100% Free to Play',
            desc: 'No paywalls. No required purchases',
            color: AppColors.primary,
            highlighted: true,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String emoji,
    required String title,
    required String desc,
    required Color color,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: highlighted
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      color: highlighted ? color : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    )),
                Text(desc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
