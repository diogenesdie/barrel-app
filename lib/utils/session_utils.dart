// =============================================================================
// session_utils.dart
//
// Utilitários de sessão e autenticação do usuário.
//
// Armazenamento:
//   - Token, usuário, username, senha e expiração: FlutterSecureStorage (cifrado)
//   - Credenciais duplicadas em SharedPreferences via [syncCredentialsToPrefs]
//     para acesso pelo home screen widget (que não pode usar SecureStorage)
//
// Preferências biométricas: lidas do objeto de usuário salvo no SecureStorage,
// espelhando os campos biometric_login, biometric_edit e biometric_remove da API.
// =============================================================================

// Dart SDK
import 'dart:convert';

// Terceiros
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Projeto — core e modelos
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device_action_repository.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group_repository.dart';

// Projeto — utils
import 'package:smart_home/utils/widget_utils.dart';

/// Utilitários estáticos para gerenciar a sessão autenticada do usuário.
class SessionUtils {
  static const _storage = FlutterSecureStorage();

  // SECTION: Chaves internas de armazenamento
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kUsername = 'auth_username';
  static const _kPassword = 'auth_password';
  static const _kExpiresAt = 'auth_expires_at';

  // SECTION: Gravação de sessão

  /// Salva todos os dados de sessão recebidos da API após login/registro.
  /// Também sincroniza com SharedPreferences e atualiza o home screen widget.
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

  /// Copia username e password para SharedPreferences, necessário para o home screen widget.
  static Future<void> syncCredentialsToPrefs() async {
    final username = await _storage.read(key: _kUsername);
    final password = await _storage.read(key: _kPassword);

    if (username != null && password != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_username', username);
      await prefs.setString('auth_password', password);
    }
  }

  // SECTION: Leitura de dados da sessão

  /// Retorna o token de autenticação ou null se não houver sessão.
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _kToken);
    } catch (e) {
      return null;
    }
  }

  /// Retorna o objeto completo do usuário (resposta da API) ou null.
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final data = await _storage.read(key: _kUser);
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Retorna o username do usuário logado ou null.
  static Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _kUsername);
    } catch (e) {
      return null;
    }
  }

  /// Retorna a senha do usuário logado (necessária para reconexão MQTT) ou null.
  static Future<String?> getPassword() async {
    try {
      return await _storage.read(key: _kPassword);
    } catch (e) {
      return null;
    }
  }

  /// Retorna a data de expiração do token ou null.
  static Future<DateTime?> getExpiresAt() async {
    try {
      final v = await _storage.read(key: _kExpiresAt);
      if (v == null) return null;
      return DateTime.tryParse(v);
    } catch (e) {
      return null;
    }
  }

  // SECTION: Remoção de sessão

  /// Remove todos os dados de sessão do SecureStorage, SharedPreferences e Hive.
  /// Chamado no logout e quando o token expira.
  static Future<void> clearSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('weather_timestamp');
    await prefs.remove('weather_data');
    await prefs.remove('coords_timestamp');
    await prefs.remove('latitude');
    await prefs.remove('longitude');
    await prefs.remove('devices');

    DeviceRepository deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);
    GroupRepository groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);
    DeviceActionRepository deviceActionRepo = DeviceActionRepository(apiBaseUrl: BASE_API_URL);

    await deviceRepo.clearAll();
    await groupRepo.clearAll();
    await deviceActionRepo.clearAll();

    updateWidget();

    await _storage.deleteAll();
  }

  // SECTION: Verificação de estado de login

  /// Retorna true se há sessão válida e não expirada. Faz logout automático se expirada.
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

  // SECTION: Atualização de perfil

  /// Envia PATCH para a API e atualiza o objeto de usuário local com os novos [data].
  /// Retorna true se bem-sucedido.
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

  // SECTION: Preferências biométricas

  /// Retorna as preferências biométricas do usuário.
  /// As chaves retornadas são: 'biometric_login', 'biometric_edit', 'biometric_remove'.
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
