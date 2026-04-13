// =============================================================================
// scene_service.dart
//
// Serviço de acesso à API REST para Cenas.
// Online-only — sem cache Hive.
//
// Endpoints cobertos:
//   GET    /api/v1/scenes
//   POST   /api/v1/scenes
//   GET    /api/v1/scenes/{id}
//   PUT    /api/v1/scenes/{id}
//   DELETE /api/v1/scenes/{id}
//   POST   /api/v1/scenes/{id}/execute
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/utils/session_utils.dart';

/// Serviço que encapsula as chamadas HTTP à API de Cenas.
class SceneService {
  final String _baseUrl;
  final http.Client _client;

  SceneService({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? BASE_API_URL,
        _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionUtils.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Retorna todas as cenas do usuário autenticado.
  Future<List<Scene>> listScenes() async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/scenes'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao listar cenas: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((j) => Scene.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Cria uma nova cena e retorna o objeto criado.
  Future<Scene> createScene(Scene scene) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl/scenes'),
      headers: headers,
      body: jsonEncode(scene.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao criar cena: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Scene.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Atualiza uma cena existente.
  Future<Scene> updateScene(Scene scene) async {
    final headers = await _authHeaders();
    final response = await _client.put(
      Uri.parse('$_baseUrl/scenes/${scene.id}'),
      headers: headers,
      body: jsonEncode(scene.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar cena: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Scene.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Remove uma cena.
  Future<void> deleteScene(int id) async {
    final headers = await _authHeaders();
    final response = await _client.delete(
      Uri.parse('$_baseUrl/scenes/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao deletar cena: ${response.statusCode}');
    }
  }

  /// Executa uma cena imediatamente e retorna o resultado por ação.
  Future<Map<String, dynamic>> executeScene(int id) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl/scenes/$id/execute'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao executar cena: ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
