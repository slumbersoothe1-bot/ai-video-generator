import 'package:flutter/foundation.dart';

import '../models/credit_model.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Manages the user's credit balance and transaction history.
class CreditsService extends ChangeNotifier {
  CreditsService(this._api);

  final ApiClient _api;

  CreditAccount? _account;
  List<CreditTransaction> _transactions = [];
  bool _loading = false;
  String? _error;

  CreditAccount? get account => _account;
  List<CreditTransaction> get transactions => _transactions;
  bool get isLoading => _loading;
  String? get error => _error;
  int get balance => _account?.balance ?? 0;

  /// Fetches the current credit balance and subscription state.
  Future<CreditAccount> fetchAccount() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/billing');
      final data = _asMap(response.data);
      final current = data['current'] as Map<String, dynamic>? ?? {};
      _account = CreditAccount.fromJson(current);
      _loading = false;
      notifyListeners();
      return _account!;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetches the credit transaction ledger.
  Future<List<CreditTransaction>> fetchHistory() async {
    try {
      final response = await _api.get('/referrals?history=1');
      final data = _asMap(response.data);
      final list = data['transactions'] as List<dynamic>? ?? [];
      _transactions =
          list.map((e) => CreditTransaction.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
      return _transactions;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException(message: 'Unexpected server response.');
  }
}
