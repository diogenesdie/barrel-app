// =============================================================================
// scenes_section.dart
//
// Seção de Cenas exibida na home screen.
// Exibe cartões horizontais de cenas com botão de execução rápida.
// Online-only — sem cache local.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/pages/scenes_page.dart';
import 'package:smart_home/services/scene_service.dart';

/// Seção de Cenas para a home screen.
/// Aceita [httpClient] opcional para facilitar testes.
class ScenesSectionWidget extends StatefulWidget {
  final http.Client? httpClient;

  const ScenesSectionWidget({super.key, this.httpClient});

  @override
  State<ScenesSectionWidget> createState() => _ScenesSectionWidgetState();
}

class _ScenesSectionWidgetState extends State<ScenesSectionWidget> {
  late final SceneService _service;

  List<Scene> _scenes = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _executingIds = {};

  @override
  void initState() {
    super.initState();
    _service = SceneService(client: widget.httpClient);
    _loadScenes();
  }

  Future<void> _loadScenes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final scenes = await _service.listScenes();
      if (mounted) setState(() => _scenes = scenes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executeScene(Scene scene) async {
    setState(() => _executingIds.add(scene.id));
    try {
      await _service.executeScene(scene.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cena executada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao executar cena: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _executingIds.remove(scene.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildHeader(context),
        ),
        const SizedBox(height: 10),
        _buildBody(context),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: Theme.of(context).primaryColorLight,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Cenas',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: 16,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScenesPage()),
              );
              _loadScenes();
            },
            child: const Text('Ver todas'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        children: [
          Text('Erro: $_error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadScenes,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }
    if (_scenes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Text('Nenhuma cena criada.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _scenes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _SceneCard(
          scene: _scenes[i],
          isExecuting: _executingIds.contains(_scenes[i].id),
          onExecute: () => _executeScene(_scenes[i]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cartão individual de cena
// ---------------------------------------------------------------------------

class _SceneCard extends StatelessWidget {
  final Scene scene;
  final bool isExecuting;
  final VoidCallback onExecute;

  const _SceneCard({
    required this.scene,
    required this.isExecuting,
    required this.onExecute,
  });

  static IconData _iconData(String? icon) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconData(scene.icon),
                size: 20, color: Theme.of(context).primaryColorLight),
            const SizedBox(width: 8),
            Text(scene.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            isExecuting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.play_arrow),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onExecute,
                  ),
          ],
        ),
      ),
    );
  }
}
