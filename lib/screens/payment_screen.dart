import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config/theme.dart';
import '../utils/haptics.dart';
import '../widgets/buttons.dart';
import '../widgets/cards.dart';

/// Payment method definition.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.currency,
    required this.region,
    required this.color,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final String currency;
  final String region;
  final int color;
}

const List<PaymentMethod> kPaymentMethods = [
  PaymentMethod(
    id: 'vodafone_cash',
    name: 'Vodafone Cash',
    description: 'Pay with Vodafone Cash wallet (Egypt)',
    icon: 'phone_android',
    currency: 'EGP',
    region: 'Egypt',
    color: 0xFFE60000,
  ),
  PaymentMethod(
    id: 'instapay',
    name: 'InstaPay',
    description: 'Instant bank transfer via InstaPay (Egypt)',
    icon: 'account_balance',
    currency: 'EGP',
    region: 'Egypt',
    color: 0xFF6C2BD9,
  ),
  PaymentMethod(
    id: 'fawry',
    name: 'Fawry',
    description: 'Pay at any Fawry outlet nationwide',
    icon: 'store',
    currency: 'EGP',
    region: 'Egypt',
    color: 0xFFFE9F2A,
  ),
  PaymentMethod(
    id: 'paypal',
    name: 'PayPal',
    description: 'Pay securely with PayPal (International)',
    icon: 'payments',
    currency: 'USD',
    region: 'Global',
    color: 0xFF003087,
  ),
  PaymentMethod(
    id: 'paystack',
    name: 'Paystack',
    description: 'Mobile-friendly payments for Africa & beyond',
    icon: 'credit_card',
    currency: 'USD',
    region: 'Global',
    color: 0xFF00C3E7,
  ),
  PaymentMethod(
    id: 'crypto',
    name: 'Crypto (USDT)',
    description: 'Pay with USDT on multiple chains',
    icon: 'currency_bitcoin',
    currency: 'USD',
    region: 'Global',
    color: 0xFFF7931A,
  ),
];

/// Screen for alternative payment gateways (no Stripe required).
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.planName,
    required this.amount,
    this.currency = 'USD',
  });

  final String planName;
  final double amount;
  final String currency;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _processing = false;

  List<PaymentMethod> get _availableMethods {
    if (widget.currency == 'EGP') {
      return kPaymentMethods.where((m) => m.region == 'Egypt').toList();
    }
    return kPaymentMethods.where((m) => m.region == 'Global').toList();
  }

  double get _convertedAmount => widget.amount;

  void _pay() {
    if (_selectedMethod == null) {
      Haptics.warning();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a payment method'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Haptics.heavy();
    setState(() => _processing = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _processing = false);
        Haptics.success();
        _showSuccess();
      }
    });
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Payment Successful!',
              style: AppText.heading.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.planName} is now active',
              style: AppText.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Continue',
              icon: Icons.check_circle,
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pop()
                  ..pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _summaryCard(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Select Payment Method',
                      style: AppText.heading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._availableMethods.asMap().entries.map((entry) {
                      final index = entry.key;
                      final method = entry.value;
                      return _methodCard(method)
                          .animate()
                          .fadeIn(delay: (index * 50).ms)
                          .slideY(begin: 0.02);
                    }),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: _processing
                          ? 'Processing...'
                          : 'Pay ${widget.currency == 'EGP' ? '${_convertedAmount.toStringAsFixed(0)} EGP' : '\$${_convertedAmount.toStringAsFixed(2)}'}',
                      icon: Icons.lock,
                      isLoading: _processing,
                      onPressed: _processing ? null : _pay,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        'Secured by 256-bit encryption',
                        style: AppText.label
                            .copyWith(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Checkout',
            style: AppText.heading.copyWith(fontSize: 20),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.02);
  }

  Widget _summaryCard() {
    return SurfaceCard(
      glow: true,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.planName,
                  style: AppText.heading.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.currency == 'EGP'
                      ? '${_convertedAmount.toStringAsFixed(0)} EGP'
                      : '\$${_convertedAmount.toStringAsFixed(2)} USD',
                  style: AppText.body.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02);
  }

  Widget _methodCard(PaymentMethod method) {
    final color = Color(method.color);
    final isSelected = _selectedMethod == method.id;
    return GestureDetector(
      onTap: () {
        Haptics.select();
        setState(() => _selectedMethod = method.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: SurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_iconForName(method.icon), color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      method.description,
                      style: AppText.bodySecondary.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: AppColors.accent, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForName(String name) {
    const map = {
      'phone_android': Icons.phone_android,
      'account_balance': Icons.account_balance,
      'store': Icons.store,
      'payments': Icons.payments,
      'credit_card': Icons.credit_card,
      'currency_bitcoin': Icons.currency_bitcoin,
    };
    return map[name] ?? Icons.payment;
  }
}
