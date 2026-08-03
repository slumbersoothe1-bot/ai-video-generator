import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/subscription_model.dart';
import '../services/billing_service.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';
import '../widgets/feedback.dart';
import 'payment_screen.dart';

/// The monetization hub: users browse subscription tiers, see their
/// credit balance, and upgrade to unlock more generations.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingService>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingService>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: billing.isLoading
                    ? const Center(child: LoadingState(label: 'Loading plans…'))
                    : billing.error != null && billing.plans.isEmpty
                        ? Center(
                            child: ErrorState(
                              message: billing.error!,
                              onRetry: () => billing.fetchPlans(),
                            ),
                          )
                        : _body(billing),
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
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Upgrade',
            style: AppText.heading.copyWith(fontSize: 20),
          ),
          const Spacer(),
          _balancePill(),
        ],
      ),
    );
  }

  Widget _balancePill() {
    final b = context.select<BillingService, int>((s) => s.current?.balance ?? 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: AppColors.accent, size: 16),
          const SizedBox(width: 4),
          Text(
            '$b credits',
            style: AppText.label.copyWith(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BillingService billing) {
    final currentTier = billing.current?.subscriptionTier ?? 'free';
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _hero(),
        const SizedBox(height: AppSpacing.lg),
        ...billing.plans.where((p) => !p.isFree).map((plan) {
          return _planCard(plan, currentTier, billing);
        }),
        const SizedBox(height: AppSpacing.lg),
        _creditPacks(billing),
      ],
    );
  }

  Widget _hero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unlock more power',
          style: AppText.display.copyWith(fontSize: 28),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Upgrade to generate more videos in higher resolution without watermarks.',
          style: AppText.bodySecondary,
        ),
      ],
    );
  }

  Widget _planCard(
    SubscriptionPlan plan,
    String currentTier,
    BillingService billing,
  ) {
    final isCurrent = plan.id == currentTier;
    final isSelected = _selectedPlanId == plan.id;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        setState(() => _selectedPlanId = plan.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : plan.isPopular
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        plan.name,
                        style: AppText.heading.copyWith(fontSize: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (plan.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'POPULAR',
                            style: AppText.label.copyWith(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  plan.priceLabel,
                  style: AppText.heading.copyWith(
                    fontSize: 20,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${plan.creditsMonthly} credits / month',
              style: AppText.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          f,
                          style: AppText.body,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.md),
            if (isCurrent)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    'Current plan',
                    style: AppText.button.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              PrimaryButton(
                label: billing.isProcessing ? 'Processing…' : 'Upgrade to ${plan.name}',
                icon: Icons.rocket_launch,
                isLoading: billing.isProcessing,
                onPressed: billing.isProcessing
                    ? null
                    : () async {
                        Haptics.select();
                        final success = await billing.subscribe(plan.id);
                        if (success && mounted) {
                          Haptics.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Welcome to ${plan.name}! ${plan.creditsMonthly} credits added.',
                              ),
                            ),
                          );
                        } else if (mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                planName: plan.name,
                                amount: double.tryParse(
                                        plan.priceLabel.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                                    9.99,
                              ),
                            ),
                          );
                        }
                      },
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.02);
  }

  Widget _creditPacks(BillingService billing) {
    final packs = [50, 200, 1000];
    final prices = [4.99, 14.99, 49.99];
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Need more credits?',
            subtitle: 'One-time credit packs — no subscription needed.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: packs.asMap().entries.map((entry) {
              final i = entry.key;
              final amount = entry.value;
              final price = prices[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i < packs.length - 1 ? AppSpacing.sm : 0,
                  ),
                  child: GestureDetector(
                    onTap: billing.isProcessing
                        ? null
                        : () async {
                            Haptics.select();
                            final success =
                                await billing.purchaseCredits(amount);
                            if (success && mounted) {
                              Haptics.success();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$amount credits added!'),
                                ),
                              );
                            } else if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    planName: '$amount Credit Pack',
                                    amount: price,
                                  ),
                                ),
                              );
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.bolt, color: AppColors.accent, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '$amount',
                            style: AppText.heading.copyWith(fontSize: 18),
                          ),
                          Text(
                            '\$${price.toStringAsFixed(2)}',
                            style: AppText.bodySecondary.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
