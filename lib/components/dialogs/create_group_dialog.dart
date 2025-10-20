import 'package:flutter/material.dart';
import 'package:smart_home/models/group.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/devices_utils.dart';

LinearGradient appGradient(BuildContext context) => LinearGradient(
      colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

class CreateGroupDialog extends StatefulWidget {
  final int currentGroupCount;
  final Group? initialGroup;

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

  final icons = ['house', 'work', 'favorite', 'gym', 'school', 'cafe', 'car', 'travel', 'garden', 'pets'];

  @override
  void initState() {
    super.initState();
    final g = widget.initialGroup;
    nameCtrl = TextEditingController(text: g?.name ?? '');
    posCtrl = TextEditingController(text: g?.position.toString() ?? widget.currentGroupCount.toString());
    isDefault = g?.isDefault ?? false;
    selectedIcon = g?.icon ?? 'house';
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);
    final isEditing = widget.initialGroup != null;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 80,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: icons.map((i) {
                      final iconData = getGroupIconData(i);
                      final isSelected = i == selectedIcon;

                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Theme.of(context).primaryColorLight.withOpacity(0.2) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? Theme.of(context).primaryColorLight : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: grad,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconData, color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: _dec('Nome do grupo'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Grupo padrão', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: isDefault,
                    onChanged: (v) => setState(() => isDefault = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
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
                      child: Text(
                        isEditing ? 'Salvar alterações' : 'Criar grupo',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              isEditing ? const SizedBox(height: 12) : Container(),
              isEditing
                  ? Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            error: true,
                            disabled: widget.initialGroup!.isDefault,
                            onPressed: () {
                              final group = widget.initialGroup!;
                              if (group.isDefault) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Não é possível excluir o grupo padrão."),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              group.position = -1;
                              Navigator.pop(context, group);
                            },
                            child: Text(
                              'Excluir grupo',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
