// =============================================================================
// routine_detail_page.dart
//
// Página de criação e edição de Rotinas.
// Permite definir nome, gatilho (dispositivo ou agendamento) e ações.
// Retorna true ao Navigator.pop quando uma rotina é salva com sucesso.
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/routine.dart';
import 'package:smart_home/services/routine_service.dart';
import 'package:smart_home/utils/session_utils.dart';

/// Página de criação/edição de rotina.
/// [routine] null → criação; preenchido → edição.
/// [service] e [httpClient] opcionais — injetáveis para testes.
class RoutineDetailPage extends StatefulWidget {
  final Routine? routine;
  final RoutineService? service;
  final http.Client? httpClient;

  const RoutineDetailPage({
    super.key,
    this.routine,
    this.service,
    this.httpClient,
  });

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final RoutineService _service;

  late TextEditingController _nameController;
  late TextEditingController _cronController;

  // Gatilho
  String _triggerType = 'schedule'; // 'device' | 'schedule'
  int? _triggerDeviceId;
  String _triggerExpectedCommand = 'on';

  // Ações
  List<_ActionDraft> _actions = [];

  // Dados carregados
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _scenes = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  bool get _isEditing => widget.routine != null;

  static const _commands = ['on', 'off', 'pulse', 'release'];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RoutineService();
    final r = widget.routine;
    _nameController = TextEditingController(text: r?.name ?? '');
    _cronController =
        TextEditingController(text: r?.trigger.cron ?? '');
    if (r != null) {
      _triggerType = r.trigger.type;
      _triggerDeviceId = r.trigger.deviceId;
      _triggerExpectedCommand =
          r.trigger.expectedState?['state'] ?? 'on';
      _actions = r.actions.map((a) {
        return _ActionDraft(
          type: a.type,
          deviceId: a.deviceId,
          command: a.command ?? 'on',
          sceneId: a.sceneId,
        );
      }).toList();
    }
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cronController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final client = widget.httpClient ?? http.Client();
    final token = await SessionUtils.getToken();
    final headers = {'Authorization': 'Bearer $token'};
    try {
      final results = await Future.wait([
        client.get(Uri.parse('$BASE_API_URL/devices'), headers: headers),
        client.get(Uri.parse('$BASE_API_URL/scenes'), headers: headers),
      ]);
      if (results[0].statusCode == 200) {
        final body =
            jsonDecode(results[0].body) as Map<String, dynamic>;
        setState(() => _devices =
            (body['data'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>());
      }
      if (results[1].statusCode == 200) {
        final body =
            jsonDecode(results[1].body) as Map<String, dynamic>;
        setState(() => _scenes =
            (body['data'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>());
      }
    } catch (_) {
      // Falha silenciosa — pickers ficarão vazios
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Valida gatilho schedule
    if (_triggerType == 'schedule' && _cronController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a expressão cron')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final trigger = _triggerType == 'device'
          ? RoutineTrigger(
              type: 'device',
              deviceId: _triggerDeviceId,
              expectedState: {'state': _triggerExpectedCommand},
            )
          : RoutineTrigger(
              type: 'schedule',
              cron: _cronController.text.trim(),
            );

      final actions = _actions.asMap().entries.map((e) {
        return RoutineAction(
          id: 0,
          routineId: widget.routine?.id ?? 0,
          type: e.value.type,
          deviceId: e.value.deviceId,
          command: e.value.type == 'device' ? e.value.command : null,
          sceneId: e.value.sceneId,
          sortOrder: e.key + 1,
        );
      }).toList();

      final routine = Routine(
        id: widget.routine?.id ?? 0,
        userId: 0,
        name: _nameController.text.trim(),
        enabled: widget.routine?.enabled ?? true,
        trigger: trigger,
        actions: actions,
      );

      if (_isEditing) {
        await _service.updateRoutine(routine);
      } else {
        await _service.createRoutine(routine);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addDeviceAction() {
    if (_devices.isEmpty) return;
    setState(() {
      _actions.add(_ActionDraft(
        type: 'device',
        deviceId: _devices.first['id'] as int,
        command: 'on',
      ));
    });
  }

  void _addSceneAction() {
    if (_scenes.isEmpty) return;
    setState(() {
      _actions.add(_ActionDraft(
        type: 'scene',
        sceneId: _scenes.first['id'] as int,
      ));
    });
  }

  void _removeAction(int index) =>
      setState(() => _actions.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Rotina' : 'Nova Rotina'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Salvar',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Nome
                  TextFormField(
                    key: const Key('routine_name_field'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da rotina',
                      hintText: 'Ex: Rotina Manhã',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nome obrigatório'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Gatilho
                  const Text('Gatilho',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTriggerSelector(),
                  const SizedBox(height: 8),
                  _buildTriggerConfig(),
                  const SizedBox(height: 24),

                  // Ações
                  const Text('Ações',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        key: const Key('add_device_action_button'),
                        onPressed:
                            _devices.isEmpty ? null : _addDeviceAction,
                        icon: const Icon(Icons.devices, size: 16),
                        label: const Text('Dispositivo'),
                      ),
                      TextButton.icon(
                        key: const Key('add_scene_action_button'),
                        onPressed:
                            _scenes.isEmpty ? null : _addSceneAction,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Cena'),
                      ),
                    ],
                  ),
                  if (_actions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhuma ação adicionada.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._actions.asMap().entries.map((e) {
                      final i = e.key;
                      final draft = e.value;
                      return draft.type == 'device'
                          ? _DeviceActionRow(
                              key: ValueKey('device_$i'),
                              index: i,
                              draft: draft,
                              devices: _devices,
                              commands: _commands,
                              onChanged: (d) =>
                                  setState(() => _actions[i] = d),
                              onRemove: () => _removeAction(i),
                            )
                          : _SceneActionRow(
                              key: ValueKey('scene_$i'),
                              index: i,
                              draft: draft,
                              scenes: _scenes,
                              onChanged: (d) =>
                                  setState(() => _actions[i] = d),
                              onRemove: () => _removeAction(i),
                            );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildTriggerSelector() {
    return Row(
      children: [
        ChoiceChip(
          key: const Key('trigger_device'),
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sensors, size: 16),
              SizedBox(width: 4),
              Text('Dispositivo'),
            ],
          ),
          selected: _triggerType == 'device',
          onSelected: (_) => setState(() => _triggerType = 'device'),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          key: const Key('trigger_schedule'),
          label: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 16),
              SizedBox(width: 4),
              Text('Agendamento'),
            ],
          ),
          selected: _triggerType == 'schedule',
          onSelected: (_) => setState(() => _triggerType = 'schedule'),
        ),
      ],
    );
  }

  Widget _buildTriggerConfig() {
    if (_triggerType == 'device') {
      if (_devices.isEmpty) {
        return const Text('Nenhum dispositivo disponível.',
            style: TextStyle(color: Colors.grey));
      }
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              key: const Key('trigger_device_picker'),
              value: _triggerDeviceId ?? _devices.first['id'] as int,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Dispositivo', isDense: true),
              items: _devices
                  .map((d) => DropdownMenuItem<int>(
                        value: d['id'] as int,
                        child: Text(d['name'] as String? ?? '${d['id']}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _triggerDeviceId = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              key: const Key('trigger_command_picker'),
              value: _triggerExpectedCommand,
              decoration: const InputDecoration(
                  labelText: 'Estado', isDense: true),
              items: ['on', 'off']
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _triggerExpectedCommand = v);
                }
              },
            ),
          ),
        ],
      );
    }

    // Schedule
    return TextFormField(
      key: const Key('trigger_cron_field'),
      controller: _cronController,
      decoration: const InputDecoration(
        labelText: 'Expressão cron',
        hintText: 'Ex: 0 8 * * * (todo dia às 8h)',
        isDense: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drafts e rows internos
// ---------------------------------------------------------------------------

class _ActionDraft {
  String type; // 'device' | 'scene'
  int? deviceId;
  String command;
  int? sceneId;

  _ActionDraft({
    required this.type,
    this.deviceId,
    this.command = 'on',
    this.sceneId,
  });

  _ActionDraft copyWith({
    String? type,
    int? deviceId,
    String? command,
    int? sceneId,
  }) =>
      _ActionDraft(
        type: type ?? this.type,
        deviceId: deviceId ?? this.deviceId,
        command: command ?? this.command,
        sceneId: sceneId ?? this.sceneId,
      );
}

class _DeviceActionRow extends StatelessWidget {
  final int index;
  final _ActionDraft draft;
  final List<Map<String, dynamic>> devices;
  final List<String> commands;
  final ValueChanged<_ActionDraft> onChanged;
  final VoidCallback onRemove;

  const _DeviceActionRow({
    super.key,
    required this.index,
    required this.draft,
    required this.devices,
    required this.commands,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.devices, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('${index + 1}.',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                key: Key('action_device_picker_$index'),
                value: draft.deviceId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Dispositivo', isDense: true),
                items: devices
                    .map((d) => DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(
                              d['name'] as String? ?? '${d['id']}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(draft.copyWith(deviceId: v));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                key: Key('action_command_picker_$index'),
                value: commands.contains(draft.command)
                    ? draft.command
                    : commands.first,
                decoration: const InputDecoration(
                    labelText: 'Comando', isDense: true),
                items: commands
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(draft.copyWith(command: v));
                },
              ),
            ),
            IconButton(
              key: Key('remove_action_$index'),
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneActionRow extends StatelessWidget {
  final int index;
  final _ActionDraft draft;
  final List<Map<String, dynamic>> scenes;
  final ValueChanged<_ActionDraft> onChanged;
  final VoidCallback onRemove;

  const _SceneActionRow({
    super.key,
    required this.index,
    required this.draft,
    required this.scenes,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text('${index + 1}.',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: Key('action_scene_picker_$index'),
                value: draft.sceneId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Cena', isDense: true),
                items: scenes
                    .map((s) => DropdownMenuItem<int>(
                          value: s['id'] as int,
                          child: Text(
                              s['name'] as String? ?? '${s['id']}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(draft.copyWith(sceneId: v));
                },
              ),
            ),
            IconButton(
              key: Key('remove_action_$index'),
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
