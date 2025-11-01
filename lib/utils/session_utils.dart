import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/utils/widget_utils.dart';
import 'package:http/http.dart' as http;

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

    await syncCredentialsToPrefs();
    updateWidget();
  }

  static Future<void> syncCredentialsToPrefs() async {
    final username = await _storage.read(key: _kUsername);
    final password = await _storage.read(key: _kPassword);

    if (username != null && password != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_username', username);
      await prefs.setString('auth_password', password);
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _kToken);
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final data = await _storage.read(key: _kUser);
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _kUsername);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getPassword() async {
    try {
      return await _storage.read(key: _kPassword);
    } catch (e) {
      return null;
    }
  }

  static Future<DateTime?> getExpiresAt() async {
    try {
      final v = await _storage.read(key: _kExpiresAt);
      if (v == null) return null;
      return DateTime.tryParse(v);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('weather_timestamp');
    await prefs.remove('weather_data');
    await prefs.remove('coords_timestamp');
    await prefs.remove('latitude');
    await prefs.remove('longitude');
    await prefs.remove('devices');
    updateWidget();

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

  static Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception("Usuário não autenticado");

      const apiUrl = "$BASE_API_URL/profile";

      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final currentRaw = await _storage.read(key: _kUser);
        Map<String, dynamic> currentUser = currentRaw != null ? jsonDecode(currentRaw) : {};

        data.forEach((key, value) {
          currentUser[key] = value;
        });

        await _storage.write(key: _kUser, value: jsonEncode(currentUser));

        await syncCredentialsToPrefs();
        updateWidget();

        return true;
      } else {
        print("Erro ao atualizar perfil: ${response.statusCode} => ${response.body}");
        return false;
      }
    } catch (e) {
      print("Falha ao atualizar perfil: $e");
      return false;
    }
  }

  static Future<Map<String, bool>> getBiometricPreferences() async {
    final user = await getUser();
    if (user == null) {
      return {
        'biometric_login': false,
        'biometric_edit': false,
        'biometric_remove': false,
      };
    }

    return {
      'biometric_login': (user['biometric_login'] as bool?) ?? false,
      'biometric_edit': (user['biometric_edit'] as bool?) ?? false,
      'biometric_remove': (user['biometric_remove'] as bool?) ?? false,
    };
  }
}
