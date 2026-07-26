import 'package:flutter/material.dart';

import '../config/theme.dart';

/// A primary action button with a neon gradient and loading state.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || widget.isLoading;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering && !isDisabled ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: isDisabled ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              gradient: isDisabled ? null : AppColors.primaryGradient,
              color: isDisabled ? AppColors.surfaceElevated : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon,
                              color: Colors.white, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.label,
                          style: AppText.button.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A subtle text button used for secondary actions (e.g. "Sign in instead").
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.accent,
        textStyle: AppText.button,
      ),
      child: Text(label),
    );
  }
}
