/// A signed-in user returned by the auth endpoints.
class UserModel {
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  final String id;
  final String email;
  final String name;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// The auth response envelope returned by /auth/login and /auth/register.
class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.expiresIn,
    this.credits = 0,
    this.referralCode,
    this.subscriptionTier,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      expiresIn: json['expires_in'] is int
          ? json['expires_in'] as int
          : int.tryParse(json['expires_in']?.toString() ?? ''),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      credits: _asInt(json['credits']),
      referralCode: json['referral_code']?.toString(),
      subscriptionTier: json['subscription_tier']?.toString(),
    );
  }

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserModel user;
  final int credits;
  final String? referralCode;
  final String? subscriptionTier;

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
