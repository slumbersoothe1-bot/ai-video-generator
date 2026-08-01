import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../utils/haptics.dart';

/// A primary action button with a neon gradient, haptic feedback, and
/// premium loading state. Every tap fires a light haptic.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovering = false;
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || widget.isLoading;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _pressing = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _pressing = false),
        onTapCancel: isDisabled ? null : () => setState(() => _pressing = false),
        onTap: isDisabled
            ? null
            : () {
                Haptics.select();
                widget.onPressed?.call();
              },
        child: AnimatedScale(
          scale: _pressing ? 0.96 : (_hovering && !isDisabled ? 1.02 : 1.0),
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: AppDurations.normal,
            height: 56,
            width: widget.fullWidth ? double.infinity : null,
            decoration: BoxDecoration(
              gradient: isDisabled ? null : AppColors.primaryGradient,
              color: isDisabled ? AppColors.surfaceElevated : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: isDisabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: _hovering ? 24 : 16,
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
                          Icon(widget.icon, color: Colors.white, size: 20),
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
      onPressed: () {
        Haptics.tap();
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.accent,
        textStyle: AppText.button,
      ),
      child: Text(label),
    );
  }
}

/// A glassmorphic icon button with haptic feedback — used for nav actions.
class GlassIconButton extends StatefulWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: () {
        Haptics.tap();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressing ? 0.90 : 1.0,
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.glassOverlay,
            borderRadius: BorderRadius.circular(widget.size / 2),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: Icon(
            widget.icon,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// A predictive prompt suggestion chip — tappable, animated, haptic.
class PromptChip extends StatefulWidget {
  const PromptChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<PromptChip> createState() => _PromptChipState();
}

class _PromptChipState extends State<PromptChip> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: () {
        Haptics.tap();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressing ? 0.95 : 1.0,
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: AppColors.accent, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppText.label.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A style selection chip with haptic feedback and animated selection state.
class StyleChip extends StatefulWidget {
  const StyleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  State<StyleChip> createState() => _StyleChipState();
}

class _StyleChipState extends State<StyleChip> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      onTap: () {
        Haptics.tick();
        widget.onSelected();
      },
      child: AnimatedScale(
        scale: _pressing ? 0.94 : 1.0,
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.selected ? AppColors.accentGradient : null,
            color: widget.selected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected ? AppColors.accent : AppColors.border,
              width: widget.selected ? 1.5 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: AppText.label.copyWith(
              color: widget.selected ? Colors.white : AppColors.textSecondary,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// A credit display pill with a subtle glow animation.
class CreditPill extends StatelessWidget {
  const CreditPill({
    super.key,
    required this.balance,
    this.onTap,
  });

  final int balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          Haptics.tap();
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt, color: AppColors.accent, size: 16),
            const SizedBox(width: 6),
            Text(
              '$balance',
              style: AppText.label.copyWith(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'credits',
              style: AppText.label.copyWith(
                color: AppColors.accent.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .shimmer(
          duration: 2.seconds,
          color: AppColors.accent.withOpacity(0.15),
        );
  }
}
