import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import '../models/referral_model.dart';
import '../services/referral_service.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';

/// The viral growth hub: users see their referral code, share it across
/// social platforms, and track how many people they've converted.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralService>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = context.watch<ReferralService>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: ref.isLoading
                    ? const Center(child: LoadingState(label: 'Loading referral hub…'))
                    : ref.error != null && ref.stats == null
                        ? Center(
                            child: ErrorState(
                              message: ref.error!,
                              onRetry: () => ref.fetchStats(),
                            ),
                          )
                        : _body(ref.stats),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Haptics.tap();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Refer & Earn', style: AppText.heading.copyWith(fontSize: 20)),
        ],
      ),
    );
  }

  Widget _body(ReferralStats? stats) {
    if (stats == null) {
      return const Center(child: Text('No referral data yet.'));
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<ReferralService>().fetchStats(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          _heroCard(stats),
          const SizedBox(height: AppSpacing.lg),
          _referralCodeCard(stats),
          const SizedBox(height: AppSpacing.lg),
          _shareButtons(stats),
          const SizedBox(height: AppSpacing.lg),
          _statsGrid(stats),
          const SizedBox(height: AppSpacing.lg),
          _howItWorks(),
        ],
      ),
    );
  }

  Widget _heroCard(ReferralStats stats) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard, color: Colors.white, size: 36),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Give 5, Get 5',
            style: AppText.display.copyWith(fontSize: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Share your code with friends. When they sign up, you both get 5 bonus credits instantly.',
            textAlign: TextAlign.center,
            style: AppText.bodySecondary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.03);
  }

  Widget _referralCodeCard(ReferralStats stats) {
    final code = stats.code ?? '------';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your referral code', style: AppText.label),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  code,
                  style: AppText.display.copyWith(
                    fontSize: 28,
                    letterSpacing: 4,
                    color: AppColors.accent,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Haptics.tap();
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            stats.shareUrl,
            style: AppText.bodySecondary.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _shareButtons(ReferralStats stats) {
    final shareText =
        'Check out AI Video Studio! Turn text into stunning videos. Use my code ${stats.code ?? ''} to get 5 free credits. ${stats.shareUrl}';
    return Row(
      children: [
        Expanded(
          child: _shareButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              Haptics.tap();
              _share(shareText);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _shareButton(
            icon: Icons.link,
            label: 'Copy Link',
            onTap: () {
              Haptics.tap();
              Clipboard.setData(ClipboardData(text: stats.shareUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppText.button.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _share(String text) {
    Share.share(text, subject: 'AI Video Studio');
  }

  Widget _statsGrid(ReferralStats stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people,
            value: '${stats.totalReferrals}',
            label: 'Total referrals',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            icon: Icons.check_circle,
            value: '${stats.rewardedReferrals}',
            label: 'Converted',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            icon: Icons.bolt,
            value: '${stats.totalCreditsEarned}',
            label: 'Credits earned',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppText.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.bodySecondary.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    final steps = [
      ('Share your code', 'Send your unique referral code or link to friends.'),
      ('They sign up', 'Your friend creates an account using your code.'),
      ('You both earn', 'You each get 5 bonus credits instantly.'),
    ];
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'How it works'),
          const SizedBox(height: AppSpacing.md),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: AppText.button.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$1, style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                        Text(step.$2, style: AppText.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.05);
          }),
        ],
      ),
    );
  }
}
