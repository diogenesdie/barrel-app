import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionUtils {
  static const _storage = FlutterSecureStorage();

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kUsername = 'auth_username';
  static const _kPassword = 'auth_password';
  static const _kExpiresAt = 'auth_expires_at';

  static Future<void> saveSession(Map<String, dynamic> apiResponse, String password) async {
    await _storage.write(key: _kToken, value: apiResponse['token'] as String?);
    await _storage.write(key: _kUser, value: jsonEncode(apiResponse));
    await _storage.write(key: _kUsername, value: apiResponse['username'] as String?);
    await _storage.write(key: _kPassword, value: password);
    if (apiResponse['expires_at'] != null) {
      await _storage.write(key: _kExpiresAt, value: apiResponse['expires_at'] as String);
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _kToken);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final data = await _storage.read(key: _kUser);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: _kUsername);
  }

  static Future<String?> getPassword() async {
    return await _storage.read(key: _kPassword);
  }

  static Future<DateTime?> getExpiresAt() async {
    final v = await _storage.read(key: _kExpiresAt);
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  static Future<void> clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('weather_timestamp');
    await prefs.remove('weather_data');
    await prefs.remove('coords_timestamp');
    await prefs.remove('latitude');
    await prefs.remove('longitude');

    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final expiresAt = await getExpiresAt();
    if (token == null) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      await clearSession();
      return false;
    }
    return true;
  }
}
