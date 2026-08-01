import 'package:flutter/foundation.dart';

import '../models/referral_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Handles referral stats and the viral sharing loop.
class ReferralService extends ChangeNotifier {
  ReferralService(this._api);

  final ApiClient _api;

  ReferralStats? _stats;
  bool _loading = false;
  String? _error;

  ReferralStats? get stats => _stats;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Fetches the user's referral code, share URL, and referral counts.
  Future<ReferralStats> fetchStats() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/referrals?stats=1');
      final data = _asMap(response.data);
      _stats = ReferralStats.fromJson(data);
      _loading = false;
      notifyListeners();
      return _stats!;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException(message: 'Unexpected server response.');
  }
}
