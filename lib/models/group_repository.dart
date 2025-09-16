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

  Future<void> addGroup(Group group) async {
    await _box.put(group.id, group);
  }

  Future<Group?> getDefaultGroup() async {
    try {
      return _box.values.firstWhere((group) => group.isDefault == true);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  List<Group> getGroups() {
    return _box.values.toList();
  }

  Future<void> removeGroup(int id) async {
    await _box.delete(id);
  }

  Future<void> clearGroups() async {
    await _box.clear();
  }

  Future<void> updateGroup(Group group) async {
    await _box.put(group.id, group);
  }

  Future<void> syncGroups() async {
    try {
      final localGroups = getGroups();
      final token = await SessionUtils.getToken();

      final response = await http.post(
        Uri.parse("$apiBaseUrl/groups"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(localGroups.map((g) => g.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        final List<dynamic> remoteGroups = jsonDecode(response.body);
        await clearGroups();
        for (final g in remoteGroups) {
          await addGroup(Group.fromJson(g));
        }
      } else {
        throw Exception("Erro ao sincronizar grupos: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  Future<void> syncGroupsGet() async {
    try {
      final token = await SessionUtils.getToken();

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

          await clearGroups(); // limpa o Hive
          for (final g in remoteGroups) {
            await addGroup(Group.fromJson(g));
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
