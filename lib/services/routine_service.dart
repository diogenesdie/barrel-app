// =============================================================================
// routine_service.dart
//
// Serviço de acesso à API REST para Rotinas.
// Online-only — sem cache Hive.
//
// Endpoints cobertos:
//   GET    /api/v1/routines
//   POST   /api/v1/routines
//   GET    /api/v1/routines/{id}
//   PUT    /api/v1/routines/{id}
//   DELETE /api/v1/routines/{id}
//   POST   /api/v1/routines/{id}/execute
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/routine.dart';
import 'package:smart_home/utils/session_utils.dart';

class RoutineService {
  final String _baseUrl;
  final http.Client _client;

  RoutineService({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? BASE_API_URL,
        _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await SessionUtils.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Routine>> listRoutines() async {
    final headers = await _authHeaders();
    final response = await _client.get(
      Uri.parse('$_baseUrl/routines'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao listar rotinas: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((j) => Routine.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Routine> createRoutine(Routine routine) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl/routines'),
      headers: headers,
      body: jsonEncode(routine.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao criar rotina: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Routine.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Routine> updateRoutine(Routine routine) async {
    final headers = await _authHeaders();
    final response = await _client.put(
      Uri.parse('$_baseUrl/routines/${routine.id}'),
      headers: headers,
      body: jsonEncode(routine.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar rotina: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Routine.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRoutine(int id) async {
    final headers = await _authHeaders();
    final response = await _client.delete(
      Uri.parse('$_baseUrl/routines/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao deletar rotina: ${response.statusCode}');
    }
  }

  Future<void> executeRoutine(int id) async {
    final headers = await _authHeaders();
    final response = await _client.post(
      Uri.parse('$_baseUrl/routines/$id/execute'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao executar rotina: ${response.statusCode}');
    }
  }

  /// Ativa ou desativa uma rotina via PUT (reenvia a rotina com enabled alterado).
  Future<Routine> toggleRoutine(int id, {required bool enabled}) async {
    final headers = await _authHeaders();
    final response = await _client.put(
      Uri.parse('$_baseUrl/routines/$id'),
      headers: headers,
      body: jsonEncode({'enabled': enabled}),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar rotina: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Routine.fromJson(body['data'] as Map<String, dynamic>);
  }
}
