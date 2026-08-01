/// Credit balance and subscription state for the current user.
class CreditAccount {
  CreditAccount({
    required this.balance,
    required this.subscriptionTier,
    required this.subscriptionStatus,
    this.subscriptionRenewsAt,
    this.totalGranted = 0,
    this.totalConsumed = 0,
  });

  factory CreditAccount.fromJson(Map<String, dynamic> json) {
    return CreditAccount(
      balance: _asInt(json['balance']),
      subscriptionTier: json['subscription_tier']?.toString() ?? 'free',
      subscriptionStatus: json['subscription_status']?.toString() ?? 'active',
      subscriptionRenewsAt: json['subscription_renews_at'] != null
          ? DateTime.tryParse(json['subscription_renews_at'].toString())
          : null,
      totalGranted: _asInt(json['total_granted']),
      totalConsumed: _asInt(json['total_consumed']),
    );
  }

  final int balance;
  final String subscriptionTier;
  final String subscriptionStatus;
  final DateTime? subscriptionRenewsAt;
  final int totalGranted;
  final int totalConsumed;

  bool get isFree => subscriptionTier == 'free';
  bool get isPaid => !isFree;

  String get tierDisplayName {
    switch (subscriptionTier) {
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro';
      case 'studio':
        return 'Studio';
      default:
        return 'Free';
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

/// A single entry in the credit transaction ledger.
class CreditTransaction {
  CreditTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.description,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id']?.toString() ?? '',
      amount: CreditAccount._asInt(json['amount']),
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final int amount;
  final String type;
  final String? description;
  final DateTime createdAt;

  bool get isGrant => amount > 0;
  bool get isDeduction => amount < 0;

  String get typeLabel {
    switch (type) {
      case 'signup_bonus':
        return 'Signup bonus';
      case 'referral_reward':
        return 'Referral reward';
      case 'subscription_grant':
        return 'Subscription credits';
      case 'generation_cost':
        return 'Video generation';
      case 'admin_adjustment':
        return 'Credit purchase';
      case 'daily_bonus':
        return 'Daily bonus';
      default:
        return type;
    }
  }
}
