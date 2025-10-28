import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_home/components/device_warning.dart';
import 'package:smart_home/components/dialogs/create_group_dialog.dart';
import 'package:smart_home/components/dialogs/share_device_dialog.dart';
import 'package:smart_home/components/no_device.dart';
import 'package:smart_home/components/sharing_notification_widget.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group.dart';
import 'package:smart_home/models/group_repository.dart';
import 'package:smart_home/models/device_share.dart';
import 'package:smart_home/models/device_share_repository.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/devices_utils.dart';
import 'package:smart_home/utils/session_utils.dart';

LinearGradient appGradient(BuildContext context) => LinearGradient(
      colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

class _GroupIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GroupIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
      ),
    );
  }
}

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

  late List<DeviceShare> _pendingShares = [];
  late DeviceShareRepository _shareRepo;
  bool isLoadingShares = false;

  Group? groupSelecionado;
  Set<int> expandedGroups = {};
  final Map<int, ExpansionTileController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);
    _groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);
    _shareRepo = DeviceShareRepository(apiBaseUrl: BASE_API_URL);

    _loadGroups();
    _loadDevices();
    _loadPendingShares();
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

  Future<void> _loadPendingShares() async {
    setState(() => isLoadingShares = true);

    try {
      final user = await SessionUtils.getUser();
      if (user == null) return;

      final shares = await _shareRepo.getShares();

      setState(() {
        _pendingShares = shares.where((share) => share.isPending && share.ownerId != user['user_id']).toList();
      });
    } catch (e) {
      print("Erro ao carregar compartilhamentos: $e");
    } finally {
      setState(() => isLoadingShares = false);
    }
  }

  Future<void> _acceptShare(int shareId) async {
    try {
      final success = await _shareRepo.acceptShare(shareId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compartilhamento aceito com sucesso!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _deviceRepo.syncDevicesGet();
        await _groupRepo.syncGroupsGet();
        await _refreshPage();
      } else {
        throw Exception('Falha ao aceitar compartilhamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao aceitar compartilhamento"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectShare(int shareId) async {
    try {
      final success = await _shareRepo.revokeShare(shareId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compartilhamento recusado"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _refreshPage();
      } else {
        throw Exception('Falha ao recusar compartilhamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao recusar compartilhamento"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshPage() async {
    await Future.wait([
      _loadDevices(),
      _loadGroups(),
      _loadPendingShares(),
    ]);
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
      if (updated.position == -1) {
        await _groupRepo.syncGroupDelete(groupSelecionado!.id);
        Group? defaultGroup = await _groupRepo.getDefaultGroup();
        setState(() {
          groups.removeWhere((g) => g.id == groupSelecionado!.id);
          for (final d in _devices.where((d) => d.groupId == groupSelecionado!.id)) {
            d.groupId = defaultGroup?.id ?? 0;
            _deviceRepo.updateDevice(d);
          }
        });
      } else {
        await _groupRepo.updateGroup(updated);
        setState(() {
          final idx = groups.indexWhere((g) => g.id == updated.id);
          if (idx >= 0) groups[idx] = updated;
        });
      }
    }
  }

  Future<void> _shareDevice() async {
    final result = await showDialog(
      context: context,
      builder: (_) => ShareDeviceDialog(deviceId: 1),
    );

    if (result == true) {
      await _loadPendingShares();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sortedGroups = [...groups]..sort((a, b) => a.position.compareTo(b.position));

    return Scaffold(
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColorLight, Theme.of(context).primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: RawMaterialButton(
          shape: const CircleBorder(),
          onPressed: () async {
            final result = await showDialog<Group>(
              context: context,
              builder: (_) => CreateGroupDialog(currentGroupCount: groups.length),
            );
            if (result != null) {
              setState(() => groups.add(result));
              await _groupRepo.addGroup(result, true);
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: _devices.isNotEmpty
            ? Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).orientation == Orientation.landscape ? 720.0 : 520.0,
                  ),
                  child: Column(
                    children: [
                      // Widget de notificação de compartilhamentos pendentes
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SharingNotificationWidget(
                          pendingShares: _pendingShares,
                          onAccept: _acceptShare,
                          onReject: _rejectShare,
                        ),
                      ),
                      // Lista reordenável de grupos
                      Expanded(
                        child: ReorderableListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;

                            final updated = [...sortedGroups];
                            final moved = updated.removeAt(oldIndex);
                            updated.insert(newIndex, moved);

                            for (int i = 0; i < updated.length; i++) {
                              updated[i].position = i;
                            }

                            setState(() {
                              groups = List.from(updated);
                            });

                            Future.microtask(() async {
                              for (final g in updated) {
                                await _groupRepo.updateGroup(g);
                              }
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
                                    _controllers[group.id]?.expand();
                                    await _deviceRepo.updateDevice(device);
                                  },
                                  builder: (context, candidateItems, rejectedItems) {
                                    final groupDevices = _devices.where((d) => d.groupId == group.id).toList();

                                    _controllers.putIfAbsent(group.id, () => ExpansionTileController());

                                    return ExpansionTile(
                                      controller: _controllers[group.id]!,
                                      key: ValueKey(group.id),
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                                      childrenPadding: EdgeInsets.zero,
                                      initiallyExpanded: expandedGroups.contains(group.id),
                                      onExpansionChanged: (expanded) {
                                        setState(() {
                                          if (expanded) {
                                            expandedGroups.add(group.id);
                                          } else {
                                            expandedGroups.remove(group.id);
                                          }
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColorLight.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              getGroupIconData(group.icon),
                                              color: Theme.of(context).primaryColorLight,
                                              size: 25,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        group.name,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey[600],
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    if (group.isDefault)
                                                      Badge(
                                                        label: const Text(
                                                          'Padrão',
                                                          style: TextStyle(fontSize: 10, color: Colors.white),
                                                        ),
                                                        backgroundColor: Theme.of(context).primaryColorLight,
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      )
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${groupDevices.length} dispositivo${groupDevices.length == 1 ? '' : 's'}",
                                                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (expandedGroups.contains(group.id) && group.icon != "share") ...[
                                            _GroupIconButton(
                                              icon: Icons.edit,
                                              tooltip: "Editar grupo",
                                              onTap: () {
                                                setState(() => groupSelecionado = group);
                                                _editGroup();
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            _GroupIconButton(
                                              icon: Icons.ios_share_rounded,
                                              tooltip: "Compartilhar grupo",
                                              onTap: () {
                                                _shareDevice();
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                      children: [
                                        ...(groupDevices.isNotEmpty
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
                                                      onFavorite: () {
                                                        setState(() => d.isFavorite = !d.isFavorite);
                                                        _deviceRepo.updateDevice(d);
                                                      },
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
                                                )
                                              ])
                                      ],
                                    );
                                  },
                                ),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(children: [
                _pendingShares.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 0, left: 16, right: 16),
                        child: SharingNotificationWidget(
                          pendingShares: _pendingShares,
                          onAccept: _acceptShare,
                          onReject: _rejectShare,
                        ),
                      )
                    : const SizedBox.shrink(),
                Padding(
                  padding: EdgeInsets.only(top: _pendingShares.isEmpty ? 16 : 0, bottom: 16, left: 16, right: 16),
                  child: noDevice(),
                ),
              ]),
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
                  child: Icon(getDeviceIcon(device, returnData: true), color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          if (device.isShared)
                            Row(
                              children: [
                                Badge(
                                  label: const Text(
                                    'Compartilhado',
                                    style: TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                  backgroundColor: Theme.of(context).primaryColorLight,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                ),
                                const SizedBox(width: 6),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            getDeviceSubtitle(device.type),
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                //share button
                const SizedBox(width: 8),
                device.isShared ? const SizedBox.shrink() : _ShareButton(onTap: () {}),
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

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);

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
            color: Colors.transparent,
          ),
          child: ShaderMask(
            shaderCallback: (rect) => grad.createShader(rect),
            blendMode: BlendMode.srcIn,
            child: const Icon(Icons.ios_share_rounded, size: 26, color: Colors.white),
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
  late String _selectedIconKey;
  late Map<String, List<dynamic>> _deviceTypeIcons;
  late DeviceRepository _deviceRepo;
  late GroupRepository _groupRepo;
  List<Group> _groups = [];
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
    _ipControl = TextEditingController(text: widget.device.ip);
    _type = widget.device.type;
    _deviceTypeIcons = getDeviceTypeIcons();
    _selectedIconKey = widget.device.icon;

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
      await _groupRepo.addGroup(result, true);
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
                              children: _deviceTypeIcons[_type]!.map((icon) {
                                final isSelected = icon['key'] == _selectedIconKey;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedIconKey = icon['key'];
                                  }),
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
                                      child: Icon(icon['icon'], color: Colors.white),
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
                                  //needs the selected icon key to array
                                  final updated = widget.device
                                    ..name = _nameCtrl.text.trim()
                                    ..type = _type
                                    ..icon = _selectedIconKey;

                                  if (_selectedGroupId != null) {
                                    updated.groupId = _selectedGroupId!;
                                  }

                                  print(updated.toJsonWithId());

                                  _deviceRepo.updateDevice(updated);
                                  Navigator.pop(context, updated);
                                },
                                child: const Text('Salvar alterações'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          error: true,
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar remoção'),
                                content: const Text(
                                  'Tem certeza que deseja desconectar este dispositivo?\n'
                                  'Essa ação apagará todas as configurações.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Desconectar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              bool ok = await resetDevice(widget.device, context, mounted);
                              if (!ok) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Não foi possível desconectar o dispositivo. Tente novamente."),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              await _deviceRepo.removeDevice(widget.device.id);
                              if (!mounted) return;
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Dispositivo desconectado e removido com sucesso."),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Desconectar e remover'),
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
