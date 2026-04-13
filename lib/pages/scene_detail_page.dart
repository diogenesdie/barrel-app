// =============================================================================
// scene_detail_page.dart
//
// Página de criação e edição de Cenas.
// Permite definir nome, ícone e lista de ações (dispositivo + comando).
// Retorna true ao Navigator.pop quando uma cena é salva com sucesso.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/scene.dart';
import 'package:smart_home/services/scene_service.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'dart:convert';

/// Página de criação/edição de cena.
/// [scene] null → criação; preenchido → edição.
/// [service] e [httpClient] opcionais — injetáveis para testes.
class SceneDetailPage extends StatefulWidget {
  final Scene? scene;
  final SceneService? service;
  final http.Client? httpClient;

  const SceneDetailPage({super.key, this.scene, this.service, this.httpClient});

  @override
  State<SceneDetailPage> createState() => _SceneDetailPageState();
}

class _SceneDetailPageState extends State<SceneDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final SceneService _service;

  late TextEditingController _nameController;
  String? _selectedIcon;
  List<_ActionDraft> _actions = [];
  List<Map<String, dynamic>> _devices = [];

  bool _isSaving = false;
  bool _isLoadingDevices = true;

  bool get _isEditing => widget.scene != null;

  static const _iconOptions = [
    ('movie', Icons.movie, 'Cinema'),
    ('home', Icons.home, 'Casa'),
    ('bed', Icons.bed, 'Dormir'),
    ('work', Icons.work, 'Trabalho'),
    ('night', Icons.nightlight, 'Noite'),
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SceneService();
    _nameController =
        TextEditingController(text: widget.scene?.name ?? '');
    _selectedIcon = widget.scene?.icon;
    if (_isEditing) {
      _actions = widget.scene!.actions
          .map((a) => _ActionDraft(deviceId: a.deviceId, command: a.command))
          .toList();
    }
    _loadDevices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final client = widget.httpClient ?? http.Client();
    try {
      final token = await SessionUtils.getToken();
      final response = await client.get(
        Uri.parse('$BASE_API_URL/devices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        setState(() => _devices = data);
      }
    } catch (_) {
      // Devices not loaded — user will see empty picker
    } finally {
      setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final actions = _actions.asMap().entries.map((e) {
        return SceneAction(
          id: 0,
          sceneId: widget.scene?.id ?? 0,
          deviceId: e.value.deviceId,
          command: e.value.command,
          sortOrder: e.key + 1,
        );
      }).toList();

      final scene = Scene(
        id: widget.scene?.id ?? 0,
        userId: 0,
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        actions: actions,
      );

      if (_isEditing) {
        await _service.updateScene(scene);
      } else {
        await _service.createScene(scene);
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

  void _addAction() {
    if (_devices.isEmpty) return;
    setState(() {
      _actions.add(_ActionDraft(
        deviceId: _devices.first['id'] as int,
        command: 'on',
      ));
    });
  }

  void _removeAction(int index) {
    setState(() => _actions.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cena' : 'Nova Cena'),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome
            TextFormField(
              key: const Key('scene_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da cena',
                hintText: 'Ex: Modo Cinema',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
            ),
            const SizedBox(height: 20),

            // Ícone
            const Text('Ícone', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _iconOptions.map((opt) {
                final isSelected = _selectedIcon == opt.$1;
                return ChoiceChip(
                  key: Key('icon_${opt.$1}'),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt.$2, size: 16),
                      const SizedBox(width: 4),
                      Text(opt.$3),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedIcon = opt.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ações',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  key: const Key('add_action_button'),
                  onPressed: _isLoadingDevices ? null : _addAction,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            if (_isLoadingDevices)
              const Center(child: CircularProgressIndicator())
            else if (_actions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nenhuma ação adicionada.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._actions.asMap().entries.map((e) {
                final i = e.key;
                final draft = e.value;
                return _ActionRow(
                  key: ValueKey(i),
                  index: i,
                  draft: draft,
                  devices: _devices,
                  onChanged: (updated) =>
                      setState(() => _actions[i] = updated),
                  onRemove: () => _removeAction(i),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _ActionDraft {
  int deviceId;
  String command;

  _ActionDraft({required this.deviceId, required this.command});

  _ActionDraft copyWith({int? deviceId, String? command}) =>
      _ActionDraft(
          deviceId: deviceId ?? this.deviceId,
          command: command ?? this.command);
}

class _ActionRow extends StatelessWidget {
  final int index;
  final _ActionDraft draft;
  final List<Map<String, dynamic>> devices;
  final ValueChanged<_ActionDraft> onChanged;
  final VoidCallback onRemove;

  const _ActionRow({
    super.key,
    required this.index,
    required this.draft,
    required this.devices,
    required this.onChanged,
    required this.onRemove,
  });

  static const _commands = ['on', 'off', 'pulse', 'release'];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('${index + 1}.',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<int>(
                key: Key('device_picker_$index'),
                value: draft.deviceId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Dispositivo', isDense: true),
                items: devices.map((d) {
                  return DropdownMenuItem<int>(
                    value: d['id'] as int,
                    child: Text(d['name'] as String? ?? '${d['id']}',
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(draft.copyWith(deviceId: v));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                key: Key('command_picker_$index'),
                value: _commands.contains(draft.command)
                    ? draft.command
                    : _commands.first,
                decoration:
                    const InputDecoration(labelText: 'Comando', isDense: true),
                items: _commands
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
