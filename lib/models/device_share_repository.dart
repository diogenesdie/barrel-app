import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_home/utils/session_utils.dart';
import 'device_share.dart';

class DeviceShareRepository {
  final String apiBaseUrl;

  DeviceShareRepository({required this.apiBaseUrl});

  Future<List<DeviceShare>> getShares() async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$apiBaseUrl/shares'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(decodedBody);

        final List<dynamic> sharesJson = responseData['data'] ?? [];

        return sharesJson.map((json) => DeviceShare.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao carregar compartilhamentos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar compartilhamentos: $e');
      return [];
    }
  }

  Future<bool> acceptShare(int shareId) async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/shares/accept?id=$shareId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao aceitar compartilhamento: $e');
      return false;
    }
  }

  Future<bool> revokeShare(int shareId) async {
    try {
      final token = await SessionUtils.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/shares/revoke?id=$shareId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao recusar compartilhamento: $e');
      return false;
    }
  }
}
