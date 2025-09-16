import 'package:flutter/material.dart';
import 'package:smart_home/models/group.dart';
import 'package:smart_home/utils/devices_utils.dart';

class CreateGroupDialog extends StatefulWidget {
  final int currentGroupCount;
  final Group? initialGroup; // 👈 se vier preenchido, entra em modo edição

  const CreateGroupDialog({
    super.key,
    required this.currentGroupCount,
    this.initialGroup,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController posCtrl;
  late bool isDefault;
  late String selectedIcon;

  final icons = [
    'house', 'work', 'favorite', 'gym', 'school',
    'cafe', 'car', 'travel', 'garden', 'pets'
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.initialGroup;
    nameCtrl = TextEditingController(text: g?.name ?? '');
    posCtrl = TextEditingController(text: g?.position.toString() ?? widget.currentGroupCount.toString());
    isDefault = g?.isDefault ?? false;
    selectedIcon = g?.icon ?? 'house';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGroup != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEditing ? 'Editar Grupo' : 'Novo Grupo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do grupo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: posCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Posição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Ícone:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedIcon,
                  items: icons.map((i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Icon(getGroupIconData(i), size: 20),
                          const SizedBox(width: 6),
                          Text(i),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedIcon = val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Padrão'),
                const Spacer(),
                Switch(
                  value: isDefault,
                  onChanged: (v) => setState(() => isDefault = v),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;

            final group = Group(
              id: widget.initialGroup?.id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
              name: nameCtrl.text.trim(),
              position: int.tryParse(posCtrl.text) ?? widget.currentGroupCount,
              icon: selectedIcon,
              isDefault: isDefault,
            );

            Navigator.pop(context, group);
          },
          child: Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
