/// Referral stats and share info for the current user.
class ReferralStats {
  ReferralStats({
    required this.code,
    required this.totalReferrals,
    required this.rewardedReferrals,
    required this.totalCreditsEarned,
    required this.currentBalance,
    required this.shareUrl,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      code: json['code']?.toString(),
      totalReferrals: _asInt(json['total_referrals']),
      rewardedReferrals: _asInt(json['rewarded_referrals']),
      totalCreditsEarned: _asInt(json['total_credits_earned']),
      currentBalance: _asInt(json['current_balance']),
      shareUrl: json['share_url']?.toString() ?? '',
    );
  }

  final String? code;
  final int totalReferrals;
  final int rewardedReferrals;
  final int totalCreditsEarned;
  final int currentBalance;
  final String shareUrl;

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
