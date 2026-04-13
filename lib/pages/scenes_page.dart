// =============================================================================
// scenes_page.dart
//
// Página de listagem e gerenciamento de Cenas.
// Permite criar novas cenas, editar e deletar existentes.
// Online-only.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/pages/scene_detail_page.dart';
import 'package:smart_home/services/scene_service.dart';

/// Página de listagem e gerenciamento de cenas do usuário.
class ScenesPage extends StatefulWidget {
  const ScenesPage({super.key});

  @override
  State<ScenesPage> createState() => _ScenesPageState();
}

class _ScenesPageState extends State<ScenesPage> {
  final SceneService _service = SceneService();

  List<Scene> _scenes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final scenes = await _service.listScenes();
      setState(() => _scenes = scenes);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteScene(Scene scene) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cena'),
        content: Text('Deseja excluir "${scene.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteScene(scene.id);
      _loadScenes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  Future<void> _openDetail({Scene? scene}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SceneDetailPage(scene: scene),
      ),
    );
    if (result == true) _loadScenes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cenas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova cena',
            onPressed: () => _openDetail(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erro: $_error',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadScenes, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_scenes.isEmpty) {
      return const Center(
        child: Text('Nenhuma cena criada.\nToque em + para criar.',
            textAlign: TextAlign.center),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadScenes,
      child: ListView.builder(
        itemCount: _scenes.length,
        itemBuilder: (_, i) {
          final scene = _scenes[i];
          return ListTile(
            key: ValueKey(scene.id),
            leading: Icon(
              _iconData(scene.icon),
              color: Theme.of(context).primaryColor,
            ),
            title: Text(scene.name),
            subtitle: Text(
                '${scene.actions.length} ação(ões)',
                style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Editar',
                  onPressed: () => _openDetail(scene: scene),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  tooltip: 'Excluir',
                  onPressed: () => _deleteScene(scene),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconData(String? icon) {
    switch (icon) {
      case 'movie':
        return Icons.movie;
      case 'home':
        return Icons.home;
      case 'bed':
        return Icons.bed;
      case 'work':
        return Icons.work;
      case 'night':
        return Icons.nightlight;
      default:
        return Icons.auto_awesome;
    }
  }
}
