import 'package:flutter/material.dart';

import '../config/theme.dart';

/// A shimmer placeholder used while images / thumbnails load.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 160,
    this.radius = AppRadius.md,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
              colors: [
                AppColors.surface,
                AppColors.surfaceElevated,
                AppColors.surface,
              ],
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// A centered error state with an optional retry action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 40),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppText.bodySecondary,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}

/// A simple centered loading indicator with optional label.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(label!, style: AppText.bodySecondary),
        ],
      ],
    );
  }
}

/// A premium animated loading indicator with a pulsing glow ring.
class PremiumLoader extends StatefulWidget {
  const PremiumLoader({
    super.key,
    this.size = 60,
    this.label,
  });

  final double size;
  final String? label;

  @override
  State<PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing glow
                  Container(
                    width: widget.size * (0.6 + 0.4 * t),
                    height: widget.size * (0.6 + 0.4 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.06 * (1 - t)),
                    ),
                  ),
                  // Rotating ring
                  Transform.rotate(
                    angle: t * 6.28,
                    child: SizedBox(
                      width: widget.size * 0.8,
                      height: widget.size * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accent),
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    ),
                  ),
                  // Center icon
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.accent,
                    size: widget.size * 0.3,
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.label!,
            style: AppText.bodySecondary,
          ),
        ],
      ],
    );
  }
}
