import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

/// Wraps platform secure storage so the JWT survives app restarts.
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  String? _cachedToken;

  Future<String?> read() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: AppConfig.tokenStorageKey);
    return _cachedToken;
  }

  Future<void> write(String token) async {
    _cachedToken = token;
    await _storage.write(key: AppConfig.tokenStorageKey, value: token);
  }

  Future<void> delete() async {
    _cachedToken = null;
    await _storage.delete(key: AppConfig.tokenStorageKey);
  }
}
