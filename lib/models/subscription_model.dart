/// A subscription plan offered in the paywall.
class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceMonthly,
    required this.creditsMonthly,
    required this.features,
    required this.maxResolution,
    required this.watermark,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      priceMonthly: (json['price_monthly'] as num?)?.toDouble() ?? 0,
      creditsMonthly: (json['credits_monthly'] as num?)?.toInt() ?? 0,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      maxResolution: json['max_resolution']?.toString() ?? '720p',
      watermark: json['watermark'] == true,
    );
  }

  final String id;
  final String name;
  final double priceMonthly;
  final int creditsMonthly;
  final List<String> features;
  final String maxResolution;
  final bool watermark;

  bool get isFree => id == 'free';
  bool get isPopular => id == 'pro';

  String get priceLabel {
    if (isFree) return 'Free';
    return '\$${priceMonthly.toStringAsFixed(2)}/mo';
  }
}
