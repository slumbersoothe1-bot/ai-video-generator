import 'package:flutter/foundation.dart';

import '../models/credit_model.dart';
import '../models/subscription_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Handles subscription plans, tier upgrades, and credit purchases.
class BillingService extends ChangeNotifier {
  BillingService(this._api);

  final ApiClient _api;

  List<SubscriptionPlan> _plans = [];
  CreditAccount? _current;
  bool _loading = false;
  bool _processing = false;
  String? _error;

  List<SubscriptionPlan> get plans => _plans;
  CreditAccount? get current => _current;
  bool get isLoading => _loading;
  bool get isProcessing => _processing;
  String? get error => _error;

  /// Fetches available plans and the user's current subscription state.
  Future<void> fetchPlans() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/billing');
      final data = _asMap(response.data);
      final planList = data['plans'] as List<dynamic>? ?? [];
      _plans = planList
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
      final currentData = data['current'] as Map<String, dynamic>? ?? {};
      _current = CreditAccount.fromJson(currentData);
      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
    }
  }

  /// Subscribes to a plan. In the self-contained system this grants
  /// credits immediately. When Stripe is connected, this will create
  /// a checkout session instead.
  Future<bool> subscribe(String planId) async {
    _processing = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post(
        '/billing',
        body: {
          'action': 'subscribe',
          'plan_id': planId,
        },
      );
      await fetchPlans();
      _processing = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _processing = false;
      notifyListeners();
      return false;
    }
  }

  /// Purchases a one-time credit pack.
  Future<bool> purchaseCredits(int amount) async {
    _processing = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post(
        '/billing',
        body: {
          'action': 'purchase_credits',
          'amount': amount,
        },
      );
      await fetchPlans();
      _processing = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _processing = false;
      notifyListeners();
      return false;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException(message: 'Unexpected server response.');
  }
}
