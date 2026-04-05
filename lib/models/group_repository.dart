// =============================================================================
// group_repository.dart
//
// Repositório de grupos de dispositivos com persistência dual:
//   - Local:  Hive (box "groupsBox") para acesso offline
//   - Remoto: API REST via HTTP para sincronização com o servidor
// =============================================================================

// Dart SDK
import 'dart:convert';

// Terceiros
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

// Projeto — utils
import 'package:smart_home/utils/session_utils.dart';

// Modelos locais (mesmo diretório)
import 'group.dart';

/// Repositório responsável pelo ciclo de vida dos grupos de dispositivos.
///
/// Gerencia criação, leitura, atualização e remoção no Hive local e na API REST.
class GroupRepository {
  static const String _boxName = "groupsBox";
  final String apiBaseUrl;

  GroupRepository({required this.apiBaseUrl});

  /// Inicializa o Hive e abre o box de grupos.
  /// Deve ser chamado em [main()] antes de [runApp].
  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(GroupAdapter());
    await Hive.openBox<Group>(_boxName);
  }

  Box<Group> get _box => Hive.box<Group>(_boxName);

  /// Salva o grupo no cache local. Se [sync] for true, envia para a API REST.
  Future<void> addGroup(Group group, bool sync) async {
    await _box.put(group.id, group);
    if (sync) {
      await syncGroupPostPut(group, true);
    }
  }

  /// Cria o grupo padrão "Casa" (id=1, isDefault=true) somente no cache local.
  /// Chamado no primeiro login para garantir que todo usuário tenha ao menos um grupo.
  Future<void> createDefaultGroup() async {
    final defaultGroup = Group(
      id: 1,
      name: 'Casa',
      icon: 'home',
      position: 0,
      isDefault: true,
    );
    await addGroup(defaultGroup, false);
    print('Grupo padrão criado: ${defaultGroup.name}');
  }

  /// Retorna o grupo padrão (isDefault == true), ou null se não existir.
  Future<Group?> getDefaultGroup() async {
    try {
      return _box.values.firstWhere((group) => group.isDefault == true);
    } catch (e) {
      return null;
    }
  }

  /// Retorna todos os grupos ordenados por posição (campo [Group.position]).
  List<Group> getGroups() {
    return _box.values.toList()..sort((a, b) => a.position.compareTo(b.position));
  }

  Future<void> removeGroup(int id) async {
    await _box.delete(id);
  }

  Future<void> clearGroups() async {
    await _box.clear();
  }

  Future<void> updateGroup(Group group) async {
    await _box.put(group.id, group);
    syncGroupPostPut(group, false);
  }

  /// Envia DELETE para a API e remove o grupo do cache Hive.
  Future<void> syncGroupDelete(int id) async {
    try {
      final token = await SessionUtils.getToken();

      if (token == null || token.isEmpty) {
        await removeGroup(id);
        return;
      }

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

  /// Envia POST (criação) ou PUT (atualização) para a API e atualiza o cache local
  /// com o grupo retornado pelo servidor.
  Future<void> syncGroupPostPut(Group group, bool newGroup) async {
    try {
      final token = await SessionUtils.getToken();

      if (token == null || token.isEmpty) return;

      final url = newGroup ? "$apiBaseUrl/groups" : "$apiBaseUrl/groups/${group.id}";
      final method = newGroup ? 'POST' : 'PUT';

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
        final decodedBody = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(decodedBody);
        final updatedGroup = Group.fromJson(decoded['data']);
        if (updatedGroup.id != group.id) {
          await _box.delete(group.id);
        }
        await addGroup(updatedGroup, false);
      } else {
        throw Exception("Erro ao sincronizar grupo: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erro na sincronização: $e");
    }
  }

  /// Baixa todos os grupos da API e substitui o cache local completamente.
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
        final decodedBody = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(decodedBody);

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

  /// Remove todos os grupos do cache local sem sincronizar com a API.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
