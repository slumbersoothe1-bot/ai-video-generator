import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      Haptics.error();
      return;
    }
    Haptics.select();
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Haptics.success();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on ApiException catch (e) {
      Haptics.error();
      _showError(e.message);
    } catch (_) {
      Haptics.error();
      _showError('Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(),
                const SizedBox(height: AppSpacing.xl),
                _form(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: AppText.bodySecondary,
                    ),
                    TextLink(
                      label: 'Sign up',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated logo badge
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Colors.white, size: 30),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.5, 0.5), duration: 500.ms),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                'AI VIDEO STUDIO',
                style: AppText.label.copyWith(
                  color: AppColors.accent,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideX(begin: -0.05),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Welcome back',
          style: AppText.display.copyWith(fontSize: 32),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(begin: 0.03),
        const SizedBox(height: 6),
        Text(
          'Sign in to generate stunning AI videos from your words.',
          style: AppText.bodySecondary,
        ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
      ],
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline, size: 20),
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
              if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
              return null;
            },
          ).animate().fadeIn(duration: 350.ms, delay: 500.ms).slideY(begin: 0.02),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  Haptics.tap();
                  setState(() => _obscure = !_obscure);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ).animate().fadeIn(duration: 350.ms, delay: 600.ms).slideY(begin: 0.02),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Sign in',
            icon: Icons.arrow_forward_rounded,
            isLoading: _loading,
            onPressed: _submit,
          ).animate().fadeIn(duration: 350.ms, delay: 700.ms).slideY(begin: 0.02),
        ],
      ),
    );
  }
}
