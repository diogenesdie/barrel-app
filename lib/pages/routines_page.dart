// =============================================================================
// routines_page.dart
//
// Página de listagem e gerenciamento de Rotinas.
// Permite criar, editar, deletar e ativar/desativar rotinas.
// Online-only.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:smart_home/models/routine.dart';
import 'package:smart_home/pages/routine_detail_page.dart';
import 'package:smart_home/services/routine_service.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  final RoutineService _service = RoutineService();

  List<Routine> _routines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final routines = await _service.listRoutines();
      setState(() => _routines = routines);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir rotina'),
        content: Text('Deseja excluir "${routine.name}"?'),
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
      await _service.deleteRoutine(routine.id);
      _loadRoutines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e')),
        );
      }
    }
  }

  Future<void> _toggleEnabled(Routine routine) async {
    try {
      await _service.toggleRoutine(routine.id, enabled: !routine.enabled);
      _loadRoutines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }

  Future<void> _openDetail({Routine? routine}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineDetailPage(routine: routine),
      ),
    );
    if (result == true) _loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova rotina',
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
                onPressed: _loadRoutines,
                child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_routines.isEmpty) {
      return const Center(
        child: Text('Nenhuma rotina criada.\nToque em + para criar.',
            textAlign: TextAlign.center),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView.builder(
        itemCount: _routines.length,
        itemBuilder: (_, i) {
          final routine = _routines[i];
          return ListTile(
            key: ValueKey(routine.id),
            leading: Icon(
              _triggerIcon(routine.trigger.type),
              color: routine.enabled
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            title: Text(routine.name),
            subtitle: Text(
              _triggerDescription(routine.trigger),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: routine.enabled,
                  onChanged: (_) => _toggleEnabled(routine),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Editar',
                  onPressed: () => _openDetail(routine: routine),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      size: 20, color: Colors.red),
                  tooltip: 'Excluir',
                  onPressed: () => _deleteRoutine(routine),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _triggerIcon(String type) =>
      type == 'device' ? Icons.sensors : Icons.schedule;

  String _triggerDescription(RoutineTrigger trigger) {
    if (trigger.type == 'device') {
      final state = trigger.expectedState?['state'] ?? '';
      return 'Dispositivo → $state';
    }
    return 'Agendamento: ${trigger.cron ?? ''}';
  }
}
