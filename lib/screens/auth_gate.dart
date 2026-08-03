import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/feedback.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Decides whether to show the login screen or go straight to the app,
/// based on whether a stored JWT was found at startup.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.initialized) {
      return const _Splash();
    }
    if (auth.isAuthenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}

/// Premium animated splash screen with a pulsing, rotating AI core.
class _Splash extends StatefulWidget {
  const _Splash();

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated AI core
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing outer glow
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final t = _pulseController.value;
                        return Container(
                          width: 120 * (0.7 + 0.3 * t),
                          height: 120 * (0.7 + 0.3 * t),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.accent.withValues(alpha: 0.15 * (1 - t)),
                                AppColors.accent.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Rotating gradient ring
                    AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, _) {
                        return Transform.rotate(
                          angle: _rotateController.value * 6.283,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.primary,
                                  AppColors.accentSecondary,
                                  AppColors.accent,
                                ],
                              ),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        );
                      },
                    ),
                    // Inner dark circle
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                      ),
                    ),
                    // Center icon
                    const Icon(Icons.auto_awesome,
                        color: AppColors.accent, size: 32),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'AI Video Studio',
                style: AppText.display.copyWith(fontSize: 24),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: AppSpacing.sm),
              const PremiumLoader(size: 32)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 600.ms),
            ],
          ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.96, 0.96),
                duration: 500.ms,
              ),
        ),
      ),
    );
  }
}
