import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
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
      await auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        referralCode: _referralController.text.trim().isEmpty
            ? null
            : _referralController.text.trim(),
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
      _showError('Unable to create account. Please try again.');
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
                      'Already have an account?',
                      style: AppText.bodySecondary,
                    ),
                    TextLink(
                      label: 'Sign in',
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
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
          child: const Icon(Icons.auto_awesome,
              color: Colors.white, size: 28),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.5, 0.5), duration: 500.ms),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: () {
            Haptics.tap();
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Create account',
          style: AppText.display.copyWith(fontSize: 32),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.03),
        const SizedBox(height: 6),
        Text(
          'Join the studio and start turning prompts into video.',
          style: AppText.bodySecondary,
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
      ],
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Name is required';
              if (v.length < 2) return 'Name is too short';
              return null;
            },
          ).animate().fadeIn(duration: 350.ms, delay: 400.ms).slideY(begin: 0.02),
          const SizedBox(height: AppSpacing.md),
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
            textInputAction: TextInputAction.next,
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
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _referralController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Referral code (optional)',
              prefixIcon: Icon(Icons.card_giftcard_outlined, size: 20),
              hintText: 'Enter a friend\'s code for 5 bonus credits',
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 700.ms).slideY(begin: 0.02),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Create account',
            icon: Icons.rocket_launch_outlined,
            isLoading: _loading,
            onPressed: _submit,
          ).animate().fadeIn(duration: 350.ms, delay: 800.ms).slideY(begin: 0.02),
        ],
      ),
    );
  }
}
