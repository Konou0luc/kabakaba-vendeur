import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_provider.dart';

class TokenStorage {
  final SharedPreferences _prefs;
  static const String _accessTokenKey = 'vendor_access_token';
  static const String _refreshTokenKey = 'vendor_refresh_token';
  static const String _userIdKey = 'vendor_user_id';
  static const String _vendorIdKey = 'vendor_id';
  static const String _pinSetKey = 'vendor_pin_set';
  static const String _pinHashKey = 'vendor_pin_hash';
  static const String _lastPhoneKey = 'vendor_last_phone';

  TokenStorage(this._prefs);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    String? vendorId,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_userIdKey, userId);
    if (vendorId != null) {
      await _prefs.setString(_vendorIdKey, vendorId);
    }
  }

  String? getAccessToken() => _prefs.getString(_accessTokenKey);
  String? getRefreshToken() => _prefs.getString(_refreshTokenKey);
  String? getUserId() => _prefs.getString(_userIdKey);
  String? getVendorId() => _prefs.getString(_vendorIdKey);

  bool hasTokens() {
    final accessToken = getAccessToken();
    final refreshToken = getRefreshToken();
    if (accessToken == null || refreshToken == null) return false;
    return _isUnexpired(accessToken) || _isUnexpired(refreshToken);
  }

  bool _isUnexpired(String token) {
    try {
      final segments = token.split('.');
      if (segments.length != 3) return false;
      final normalizedPayload = base64Url.normalize(segments[1]);
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(normalizedPayload)),
      );
      final expiration = (payload as Map<String, dynamic>)['exp'];
      if (expiration is! num) return false;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiration > nowSeconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> savePinHash(String hash) async {
    await _prefs.setString(_pinHashKey, hash);
    await _prefs.setBool(_pinSetKey, true);
  }

  String? getPinHash() => _prefs.getString(_pinHashKey);
  bool get hasPinSet => _prefs.getBool(_pinSetKey) ?? false;

  String? getLastPhone() => _prefs.getString(_lastPhoneKey);
  Future<void> saveLastPhone(String phone) =>
      _prefs.setString(_lastPhoneKey, phone);

  Future<void> clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_vendorIdKey);
  }

  Future<void> clearAll() async {
    await clearTokens();
    await _prefs.remove(_pinHashKey);
    await _prefs.remove(_pinSetKey);
    await _prefs.remove(_lastPhoneKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TokenStorage(prefs);
});
