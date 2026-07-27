import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
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

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'AI Video Studio',
                style: AppText.display.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
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
