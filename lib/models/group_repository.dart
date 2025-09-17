import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/utils/session_utils.dart';
import 'group.dart';

class GroupRepository {
  static const String _boxName = "groupsBox";
  final String apiBaseUrl;

  GroupRepository({required this.apiBaseUrl});

  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(GroupAdapter());
    await Hive.openBox<Group>(_boxName);
  }

  Box<Group> get _box => Hive.box<Group>(_boxName);

  Future<void> addGroup(Group group, bool sync) async {
    await _box.put(group.id, group);
    if (sync) {
      await syncGroupPostPut(group, true);
    }
  }

  Future<Group?> getDefaultGroup() async {
    try {
      return _box.values.firstWhere((group) => group.isDefault == true);
    } catch (e) {
      return null;
    }
  }

  List<Group> getGroups() {
    return _box.values.toList();
  }

  Future<void> removeGroup(int id) async {
    await _box.delete(id);
    await synGroupDelete(id);
  }

  Future<void> clearGroups() async {
    await _box.clear();
  }

  Future<void> updateGroup(Group group) async {
    await _box.put(group.id, group);
    syncGroupPostPut(group, false);
  }

  Future<void> synGroupDelete(int id) async {
    try {
      final token = await SessionUtils.getToken();

      if (token == null || token.isEmpty) return;

      final response = await http.delete(
        Uri.parse("$apiBaseUrl/groups/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        await removeGroup(id);
      } else {
        throw Exception("Erro ao deletar grupo: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  Future<void> syncGroupPostPut(Group group, bool newGroup) async {
    try {
      final token = await SessionUtils.getToken();

      if (token == null || token.isEmpty) return;

      final url = newGroup ? "$apiBaseUrl/groups" : "$apiBaseUrl/groups/${group.id}";
      final method = newGroup ? 'POST' : 'PUT';

      group.toJson();
      print("Enviando grupo: ${group.toJson()}");

      final response = await (method == 'POST'
          ? http.post(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(group.toJson()),
            )
          : http.put(
              Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $token",
              },
              body: jsonEncode(group.toJson()),
            ));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final updatedGroup = Group.fromJson(decoded['data']);
        await addGroup(updatedGroup, false);
      } else {
        throw Exception("Erro ao sincronizar grupo: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  Future<void> syncGroupsGet() async {
    try {
      final token = await SessionUtils.getToken();

      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse("$apiBaseUrl/groups"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final List<dynamic> remoteGroups = decoded['data'];

          await clearGroups();
          for (final g in remoteGroups) {
            await addGroup(Group.fromJson(g), false);
          }
        } else {
          throw Exception("Formato inesperado da resposta da API");
        }
      } else {
        throw Exception("Erro ao buscar grupos: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }
}
