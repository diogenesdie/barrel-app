import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_home/components/device_warning.dart';
import 'package:smart_home/components/dialogs/create_group_dialog.dart';
import 'package:smart_home/components/no_device.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group.dart';
import 'package:smart_home/models/group_repository.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/devices_utils.dart';

LinearGradient appGradient(BuildContext context) => LinearGradient(
      colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late List<Device> _devices = [];
  late DeviceRepository _deviceRepo;
  bool isLoadingDevices = false;

  late List<Group> groups = [];
  late GroupRepository _groupRepo;
  bool isLoadingGroups = false;

  Group? groupSelecionado;

  @override
  void initState() {
    super.initState();
    _deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);
    _groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);

    _loadGroups();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoadingDevices = true);

    try {
      setState(() {
        _devices = _deviceRepo.getDevices();
      });
    } catch (e) {
      print("Erro ao carregar devices: $e");
    } finally {
      setState(() => isLoadingDevices = false);
    }
  }

  Future<void> _loadGroups() async {
    setState(() => isLoadingGroups = true);

    try {
      setState(() {
        groups = _groupRepo.getGroups();
      });
    } catch (e) {
      print("Erro ao carregar grupos: $e");
    } finally {
      setState(() => isLoadingGroups = false);
    }
  }

  Future<void> _editGroup() async {
    final updated = await showDialog<Group>(
      context: context,
      builder: (_) => CreateGroupDialog(
        currentGroupCount: groups.length,
        initialGroup: groupSelecionado,
      ),
    );

    if (updated != null) {
      await _groupRepo.updateGroup(updated);
      setState(() {
        final idx = groups.indexWhere((g) => g.id == updated.id);
        if (idx >= 0) groups[idx] = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sortedGroups = [...groups]..sort((a, b) => a.position.compareTo(b.position));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).orientation == Orientation.landscape ? 720.0 : 520.0,
            ),
            child: _devices.isNotEmpty
                ? ReorderableListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;

                      final moved = sortedGroups.removeAt(oldIndex);
                      sortedGroups.insert(newIndex, moved);

                      // atualiza positions e salva no Hive
                      for (int i = 0; i < sortedGroups.length; i++) {
                        sortedGroups[i].position = i;
                        await _groupRepo.updateGroup(sortedGroups[i]);
                      }

                      setState(() {
                        groups = List.from(sortedGroups);
                      });
                    },
                    children: [
                      for (final group in sortedGroups)
                        Theme(
                          key: ValueKey(group.id),
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: DragTarget<Device>(
                            onWillAccept: (data) => data != null && data.groupId != group.id,
                            onAccept: (device) async {
                              setState(() {
                                device.groupId = group.id;
                              });
                              await _deviceRepo.updateDevice(device);
                            },
                            builder: (context, candidateItems, rejectedItems) {
                              final groupDevices = _devices.where((d) => d.groupId == group.id).toList();

                              return ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                                childrenPadding: EdgeInsets.zero,
                                initiallyExpanded: true,
                                title: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColorLight.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        getGroupIconData(group.icon),
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        group.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: groupDevices.isNotEmpty
                                    ? groupDevices.map((d) {
                                        return LongPressDraggable<Device>(
                                          data: d,
                                          feedback: Material(
                                            color: Colors.transparent,
                                            child: Opacity(
                                              opacity: 0.7,
                                              child: SizedBox(
                                                width: screenWidth - 32,
                                                child: _DeviceCard(
                                                  device: d,
                                                  onFavorite: () {},
                                                  onOpen: () {},
                                                ),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.4,
                                            child: _DeviceCard(
                                              device: d,
                                              onFavorite: () => setState(() => d.isFavorite = !d.isFavorite),
                                              onOpen: () {},
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: _DeviceCard(
                                              device: d,
                                              onFavorite: () => setState(() => d.isFavorite = !d.isFavorite),
                                              onOpen: () async {
                                                final updated = await Navigator.push<Device>(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => DeviceEditPage(device: d)),
                                                );
                                                if (updated != null) {
                                                  setState(() {
                                                    final idx = _devices.indexWhere((e) => e.id == updated.id);
                                                    if (idx >= 0) _devices[idx] = updated;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      }).toList()
                                    : [
                                        deviceWarning(
                                          "Nenhum dispositivo neste grupo",
                                          "Arraste dispositivos para cá ou altere ao editar um dispositivo.",
                                          FontAwesomeIcons.boxOpen,
                                        ),
                                      ],
                              );
                            },
                          ),
                        )
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: noDevice(),
                  ),
          ),
        ),
      ),
    );
  }
}

enum DeviceType { rfControl, feeder, unknown }

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  const _DeviceCard({
    required this.device,
    required this.onFavorite,
    required this.onOpen,
  });

  IconData _iconForType(String t) {
    switch (t) {
      case 'feeder':
        return Icons.pets;
      case 'rfControl':
        return Icons.settings_remote;
      case "lightbulb":
      case "light":
        return FontAwesomeIcons.lightbulb;
      case "switch":
        return FontAwesomeIcons.powerOff;
      case "trigger":
        return FontAwesomeIcons.bolt;
      default:
        return Icons.device_unknown;
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case "feeder":
        return 'Alimentador Automático';
      case "rfControl":
        return 'Controle RF Inteligente';
      case "lightbulb":
      case "light":
        return 'Lâmpada Inteligente';
      case "switch":
        return 'Interruptor Inteligente';
      case "trigger":
        return 'Gatilho Inteligente';
      default:
        return 'Dispositivo Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForType(device.type), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _typeLabel(device.type),
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _GradientStarButton(
                  selected: device.isFavorite,
                  onTap: onFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientStarButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _GradientStarButton({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);
    final icon = selected ? Icons.star : Icons.star_border;

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            shape: BoxShape.circle,
            color: selected ? Theme.of(context).primaryColorLight.withOpacity(0.2) : Colors.transparent,
          ),
          child: ShaderMask(
            shaderCallback: (rect) => grad.createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Icon(icon, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class DeviceEditPage extends StatefulWidget {
  final Device device;

  const DeviceEditPage({super.key, required this.device});

  @override
  State<DeviceEditPage> createState() => _DeviceEditPageState();
}

class _DeviceEditPageState extends State<DeviceEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ipControl;
  late String _type;
  late IconData _selectedIcon;
  late DeviceRepository _deviceRepo;
  late GroupRepository _groupRepo;
  List<Group> _groups = [];
  int? _selectedGroupId;

  final Map<String, List<IconData>> _iconOptions = {
    "rfControl": [
      Icons.settings_remote,
      Icons.garage,
      Icons.radio,
      Icons.wifi,
    ],
    "feeder": [
      Icons.pets,
      Icons.restaurant,
      Icons.rice_bowl,
      Icons.local_dining,
      Icons.fastfood,
    ],
    "lightbulb": [
      Icons.lightbulb,
      Icons.wb_incandescent,
      Icons.wb_sunny,
    ],
    "switch": [FontAwesomeIcons.powerOff, FontAwesomeIcons.toggleOn, FontAwesomeIcons.plug, FontAwesomeIcons.lightbulb],
    "trigger": [FontAwesomeIcons.bolt, FontAwesomeIcons.bell, FontAwesomeIcons.bullhorn, FontAwesomeIcons.triangleExclamation],
    "unknown": [
      Icons.device_unknown,
      Icons.question_mark,
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
    _ipControl = TextEditingController(text: widget.device.ip);
    _type = widget.device.type;
    _selectedIcon = _iconOptions[_type]!.first;

    _deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);
    _groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);

    _selectedGroupId = widget.device.groupId; // valor atual do device

    _loadGroups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      setState(() {
        _groups = _groupRepo.getGroups();
      });
    } catch (e) {
      print("Erro ao carregar grupos: $e");
    }
  }

  Future<void> _createNewGroup() async {
    final result = await showDialog<Group>(
      context: context,
      builder: (_) => CreateGroupDialog(currentGroupCount: _groups.length),
    );

    if (result != null) {
      await _groupRepo.addGroup(result);
      setState(() {
        _groups.add(result);
        _selectedGroupId = result.id;
      });
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final maxCardWidth = isLandscape ? 520.0 : 420.0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, widget.device);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar dispositivo'),
          elevation: 10,
          shadowColor: Colors.grey[200],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                  onPressed: () {
                    bool newFav = !widget.device.isFavorite;
                    setState(() {
                      widget.device.isFavorite = newFav;
                      _deviceRepo.updateDevice(widget.device);
                    });
                  },
                  icon: widget.device.isFavorite ? const Icon(Icons.star) : const Icon(Icons.star_border)),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _iconOptions[_type]!.map((icon) {
                                final isSelected = icon == _selectedIcon;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedIcon = icon),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Theme.of(context).primaryColorLight.withOpacity(0.2) : Colors.grey.shade200,
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
                                      child: Icon(icon, color: Colors.white),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameCtrl,
                          decoration: _dec('Nome do dispositivo'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: _selectedGroupId ?? (_groups.isNotEmpty ? _groups.first.id : null),
                          decoration: _dec('Grupo do dispositivo'),
                          items: [
                            ..._groups.map((g) {
                              return DropdownMenuItem<int>(
                                value: g.id,
                                child: Text(g.name),
                              );
                            }),
                            const DropdownMenuItem<int>(
                              value: -1,
                              child: Text('+ Criar novo grupo'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == -1) {
                              await _createNewGroup();
                            } else if (value != null) {
                              setState(() => _selectedGroupId = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Opacity(
                                opacity: 0.5,
                                child: TextField(
                                  onTap: () {
                                    if (widget.device.ip.isNotEmpty) {
                                      Clipboard.setData(ClipboardData(text: widget.device.ip));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("IP copiado para a área de transferência"),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  controller: _ipControl,
                                  readOnly: true,
                                  decoration: _dec('IP do dispositivo'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GradientButton(
                                onPressed: () {
                                  final updated = widget.device
                                    ..name = _nameCtrl.text.trim()
                                    ..type = _type;
                                  if (_selectedGroupId != null) {
                                    updated.groupId = _selectedGroupId!;
                                  }

                                  _deviceRepo.updateDevice(updated);
                                  Navigator.pop(context, updated);
                                },
                                child: const Text('Salvar alterações'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context, widget.device),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
