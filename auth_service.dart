import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Handles authentication against /auth/login and /auth/register.
class AuthService extends ChangeNotifier {
  AuthService({
    required this.api,
    required this.tokenStore,
  });

  final ApiClient api;
  final TokenStore tokenStore;

  UserModel? _user;
  String? _token;
  bool _initialized = false;

  UserModel? get currentUser => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get initialized => _initialized;

  /// Loads any persisted token on app start.
  Future<void> init() async {
    final stored = await tokenStore.read();
    if (stored != null && stored.isNotEmpty) {
      _token = stored;
      api.updateToken(stored);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    final session = AuthSession.fromJson(_asMap(response.data));
    await _persist(session);
    return session.user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
      authenticated: false,
    );
    final session = AuthSession.fromJson(_asMap(response.data));
    await _persist(session);
    return session.user;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await tokenStore.delete();
    api.updateToken(null);
    notifyListeners();
  }

  Future<void> _persist(AuthSession session) async {
    _token = session.accessToken;
    _user = session.user;
    await tokenStore.write(session.accessToken);
    api.updateToken(session.accessToken);
    notifyListeners();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // fall through
      }
    }
    throw ApiException(message: 'Unexpected server response.');
  }
}
