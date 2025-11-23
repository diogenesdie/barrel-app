import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/components/device_warning.dart';
import 'package:smart_home/components/dialogs/create_group_dialog.dart';
import 'package:smart_home/components/dialogs/share_device_dialog.dart';
import 'package:smart_home/components/no_device.dart';
import 'package:smart_home/components/sharing_notification_widget.dart';
import 'package:smart_home/core/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/device_action.dart';
import 'package:smart_home/models/device_repository.dart';
import 'package:smart_home/models/group.dart';
import 'package:smart_home/models/group_repository.dart';
import 'package:smart_home/models/device_share.dart';
import 'package:smart_home/models/device_share_repository.dart';
import 'package:smart_home/pages/auth_page.dart';
import 'package:smart_home/utils/biometric_utils.dart';
import 'package:smart_home/utils/devices_utils.dart';
import 'package:smart_home/utils/session_utils.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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

  final GlobalKey _firstGroupKey = GlobalKey();
  List<TargetFocus> _tutorialTargets = [];
  bool _tutorialShown = false;

  int? _tutorialDeviceId;
  bool _deviceTutorialShown = false;

  final Map<int, GlobalKey> _deviceTutorialKeys = {};
  final Map<int, GlobalKey> _deviceShareKeys = {};
  final Map<int, GlobalKey> _deviceFavoriteKeys = {};

  GlobalKey _ensureDeviceTutorialKey(int deviceId) {
    return _deviceTutorialKeys.putIfAbsent(
      deviceId,
      () => GlobalKey(debugLabel: 'device_tutorial_$deviceId'),
    );
  }

  GlobalKey _ensureDeviceShareKey(int deviceId) {
    return _deviceShareKeys.putIfAbsent(
      deviceId,
      () => GlobalKey(debugLabel: 'device_share_$deviceId'),
    );
  }

  GlobalKey _ensureDeviceFavoriteKey(int deviceId) {
    return _deviceFavoriteKeys.putIfAbsent(
      deviceId,
      () => GlobalKey(debugLabel: 'device_favorite_$deviceId'),
    );
  }

  @override
  void initState() {
    super.initState();
    _deviceRepo = DeviceRepository(apiBaseUrl: BASE_API_URL);
    _groupRepo = GroupRepository(apiBaseUrl: BASE_API_URL);
    _shareRepo = DeviceShareRepository(apiBaseUrl: BASE_API_URL);

    _initializeData();
  }

  @override
  void dispose() {
    _deviceTutorialKeys.clear();
    _deviceShareKeys.clear();
    _deviceFavoriteKeys.clear();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadGroups();
    await _loadDevices();
    await _loadPendingShares();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeShowReorderTutorial();
    });
  }

  Future<void> _maybeShowReorderTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    _tutorialShown = prefs.getBool("tutorial_reorder_shown") ?? false;

    if (groups.isNotEmpty && !_tutorialShown) {
      await Future.delayed(const Duration(milliseconds: 500));
      _initTutorialTargets();

      TutorialCoachMark(
        targets: _tutorialTargets,
        colorShadow: Colors.black.withOpacity(0.7),
        textSkip: "Pular",
        opacityShadow: 0.8,
        onFinish: () async {
          await prefs.setBool("tutorial_reorder_shown", true);
        },
      ).show(context: context);
    }
  }

  void _initTutorialTargets() {
    _tutorialTargets = [
      TargetFocus(
        identify: "reorder_groups",
        keyTarget: _firstGroupKey,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Organize seus grupos",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Você pode arrastar os grupos e dispositivos para mudar a ordem deles na tela.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _maybeShowDeviceDragTutorial() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    _deviceTutorialShown = prefs.getBool("tutorial_device_drag_shown") ?? false;

    if (!_deviceTutorialShown && _tutorialDeviceId != null) {
      // Get the keys for the tutorial device
      final deviceKey = _deviceTutorialKeys[_tutorialDeviceId!];
      final shareKey = _deviceShareKeys[_tutorialDeviceId!];
      final favoriteKey = _deviceFavoriteKeys[_tutorialDeviceId!];

      if (deviceKey == null || shareKey == null || favoriteKey == null) {
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      TutorialCoachMark(
        targets: [
          TargetFocus(
            identify: "drag_device",
            keyTarget: deviceKey,
            shape: ShapeLightFocus.RRect,
            radius: 8,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Arraste para mover",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Você pode segurar e arrastar este dispositivo para outro grupo.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TargetFocus(
            identify: "favorite_device",
            keyTarget: favoriteKey,
            shape: ShapeLightFocus.Circle,
            radius: 8,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Adicionar aos favoritos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Toque aqui para adicionar este dispositivo como widget na tela inicial do seu celular.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TargetFocus(
            identify: "share_device",
            keyTarget: shareKey,
            shape: ShapeLightFocus.Circle,
            radius: 8,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Compartilhar dispositivo",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Toque aqui para compartilhar este dispositivo com outros usuários.",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        colorShadow: Colors.black.withOpacity(0.7),
        textSkip: "Pular",
        opacityShadow: 0.8,
        onFinish: () async {
          await prefs.setBool("tutorial_device_drag_shown", true);
          setState(() {
            _tutorialDeviceId = null;
            // Clear the keys for the tutorial device
            _deviceTutorialKeys.clear();
            _deviceShareKeys.clear();
            _deviceFavoriteKeys.clear();
          });
        },
        onSkip: () {
          setState(() {
            _tutorialDeviceId = null;
            // Clear the keys for the tutorial device
            _deviceTutorialKeys.clear();
            _deviceShareKeys.clear();
            _deviceFavoriteKeys.clear();
          });
          return true;
        },
      ).show(context: context);
    }
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
                              _controllers.clear();
                              for (final g in groups) {
                                _controllers[g.id] = ExpansionTileController();
                              }
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
                                  key: group.id == sortedGroups.first.id ? _firstGroupKey : null,
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

                                            final groupDevices = _devices.where((d) => d.groupId == group.id).toList();
                                            if (groupDevices.isNotEmpty && !_deviceTutorialShown && _tutorialDeviceId == null) {
                                              _tutorialDeviceId = groupDevices.first.id;

                                              _ensureDeviceTutorialKey(_tutorialDeviceId!);
                                              _ensureDeviceShareKey(_tutorialDeviceId!);
                                              _ensureDeviceFavoriteKey(_tutorialDeviceId!);

                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                _maybeShowDeviceDragTutorial();
                                              });
                                            }
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
                                          ],
                                        ],
                                      ),
                                      children: [
                                        ...(groupDevices.isNotEmpty
                                            ? groupDevices.map((d) {
                                                final isTutorialDevice = d.id == _tutorialDeviceId;

                                                return RepaintBoundary(
                                                  key: ValueKey('repaint_${d.id}'),
                                                  child: LongPressDraggable<Device>(
                                                    data: d,
                                                    feedback: Material(
                                                      color: Colors.transparent,
                                                      child: Opacity(
                                                        opacity: 0.7,
                                                        child: SizedBox(
                                                          width: screenWidth - 32,
                                                          child: _DeviceCard(
                                                            context: context,
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
                                                        context: context,
                                                        device: d,
                                                        onFavorite: () => setState(() => d.isFavorite = !d.isFavorite),
                                                        onOpen: () {},
                                                      ),
                                                    ),
                                                    child: Container(
                                                      key: isTutorialDevice ? _ensureDeviceTutorialKey(d.id) : null,
                                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                                      child: _DeviceCard(
                                                        context: context,
                                                        device: d,
                                                        onFavorite: () {
                                                          setState(() => d.isFavorite = !d.isFavorite);
                                                          _deviceRepo.updateDevice(d);
                                                        },
                                                        onOpen: () async {
                                                          final ok = await BiometricUtils.authenticate(
                                                            'edit_device',
                                                            reason: "Autentique-se para editar o dispositivo",
                                                          );
                                                          if (!ok) return;

                                                          final result = await Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (_) => DeviceEditPage(device: d)),
                                                          );
                                                          if (result is Device) {
                                                            setState(() {
                                                              final idx = _devices.indexWhere((e) => e.id == result.id);
                                                              if (idx >= 0) {
                                                                _devices[idx] = result;
                                                              }
                                                            });
                                                          }
                                                          if (result == true) {
                                                            await _refreshPage();
                                                          }
                                                        },
                                                        favoriteKey: isTutorialDevice ? _ensureDeviceFavoriteKey(d.id) : null,
                                                        shareKey: isTutorialDevice ? _ensureDeviceShareKey(d.id) : null,
                                                      ),
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
  final BuildContext context;
  final GlobalKey? favoriteKey;
  final GlobalKey? shareKey;

  const _DeviceCard({
    required this.device,
    required this.onFavorite,
    required this.onOpen,
    required this.context,
    this.favoriteKey,
    this.shareKey,
  });

  Future<void> _shareDevice(int deviceId) async {
    await showDialog(
      context: context,
      builder: (_) => ShareDeviceDialog(deviceId: deviceId),
    );
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
                const SizedBox(width: 8),
                device.isShared
                    ? const SizedBox.shrink()
                    : _ShareButton(
                        onTap: () {
                          _shareDevice(device.id);
                        },
                        shareKey: shareKey),
                const SizedBox(width: 8),
                _GradientStarButton(
                  favoriteKey: favoriteKey,
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
  final GlobalKey? shareKey;

  const _ShareButton({required this.onTap, this.shareKey});

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);

    return Material(
      key: shareKey,
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
  final GlobalKey? favoriteKey;

  const _GradientStarButton({required this.selected, required this.onTap, this.favoriteKey});

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);
    final icon = selected ? Icons.star : Icons.star_border;

    return Material(
      key: favoriteKey,
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

    _selectedGroupId = widget.device.groupId;

    if (widget.device.actions != null) {
      for (var action in widget.device.actions!) {
        _triggerActions[action.triggerEvent] = {
          'deviceId': action.targetDeviceId,
          'deviceName': '',
          'action': action.actionType,
        };
      }
    }

    _loadGroups();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipControl.dispose(); // 👈 adicione isso também
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

  final List<Map<String, dynamic>> _triggers = [
    {"key": "single_click", "label": "Clique"},
    {"key": "double_click", "label": "Clique duplo"},
    {"key": "triple_click", "label": "Clique triplo"},
    {"key": "long_click", "label": "Clique longo"},
  ];

  final Map<String, Map<String, dynamic>> _triggerActions = {};

  List<Device> _availableDevices = [];

  Future<void> _loadAvailableDevices() async {
    try {
      final devices = _deviceRepo.getDevices();
      final filtered = devices.where((d) => d.id != widget.device.id).toList();

      if (filtered.isEmpty) {
        setState(() {
          _availableDevices = [];
          _triggerActions.clear();
        });
        return;
      }

      setState(() {
        _availableDevices = filtered;

        for (var key in _triggerActions.keys) {
          final deviceId = _triggerActions[key]?['deviceId'];
          if (deviceId != null) {
            final device = _availableDevices.firstWhere(
              (d) => d.id == deviceId,
              orElse: () => _availableDevices.first,
            );
            _triggerActions[key]!['deviceName'] = device.name;
          }
        }
      });
    } catch (e) {
      print("Erro ao carregar dispositivos disponíveis: $e");
    }
  }

  List<Widget> _buildTriggerActions(BuildContext context) {
    // dispara carregamento, mas não bloqueia a interface
    if (_availableDevices.isEmpty) {
      _loadAvailableDevices();
    }

    return _triggers.map((trigger) {
      final key = trigger['key'];
      final current = _triggerActions[key];

      return Card(
        elevation: 6,
        color: Colors.white.withOpacity(0.7),
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trigger['label'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (current != null && current['deviceId'] != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _triggerActions.remove(key);
                        });
                      },
                      tooltip: 'Remover ação',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _availableDevices.any((d) => d.id == current?['deviceId'])
                    ? current != null
                        ? current['deviceId']
                        : null
                    : null,
                decoration: _dec('Dispositivo alvo'),
                dropdownColor: Colors.white,
                isExpanded: true,
                items: _availableDevices.isNotEmpty
                    ? _availableDevices.map((d) {
                        return DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(d.name),
                        );
                      }).toList()
                    : [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Carregando dispositivos...'),
                        )
                      ],
                onChanged: (value) {
                  if (value != null && _availableDevices.isNotEmpty) {
                    final selectedDevice = _availableDevices.firstWhere(
                      (d) => d.id == value,
                      orElse: () => _availableDevices.first, // fallback seguro
                    );

                    final actionOptions = getActionsForType(selectedDevice.type);

                    setState(() {
                      _triggerActions[key] = {
                        'deviceId': selectedDevice.id,
                        'deviceName': selectedDevice.name,
                        'action': actionOptions.first,
                      };
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              if (current != null && current['deviceId'] != null)
                DropdownButtonFormField<String>(
                  value: getActionDisplayName(current['action']),
                  decoration: _dec('Ação'),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  items: getActionsForType(
                    _availableDevices
                        .firstWhere(
                          (d) => d.id == current['deviceId'],
                          orElse: () => _availableDevices.first,
                        )
                        .type,
                  ).map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _triggerActions[key]!['action'] = value;
                      });
                    }
                  },
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

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
                  color: Colors.white.withOpacity(0.7),
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
                          dropdownColor: Colors.white,
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
                        if (_type.toLowerCase() == 'trigger') ...[
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Ações de Gatilho",
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown.shade800,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._buildTriggerActions(context),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: GradientButton(
                                onPressed: () {
                                  try {
                                    final actions = _triggerActions.entries
                                        .where((e) => e.value['deviceId'] != null)
                                        .map((e) => DeviceAction(
                                              id: 0,
                                              triggerEvent: e.key,
                                              targetDeviceId: e.value['deviceId'],
                                              actionType: getActionCommand(e.value['action']),
                                              targetDeviceName: '',
                                              targetDeviceIp: '',
                                              targetDeviceQueue: '',
                                              triggerDeviceId: widget.device.id,
                                            ))
                                        .toList();

                                    final updated = widget.device.copyWith(
                                      name: _nameCtrl.text.trim(),
                                      type: _type,
                                      icon: _selectedIconKey,
                                      groupId: _selectedGroupId,
                                      actions: actions.isEmpty ? null : actions,
                                    );

                                    _deviceRepo.updateDevice(updated);
                                    Navigator.pop(context, updated);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Dispositivo atualizado com sucesso."),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } catch (e) {
                                    print("Erro ao salvar dispositivo: $e");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Erro ao salvar dispositivo. Tente novamente."),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
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
                            final ok = await BiometricUtils.authenticate(
                              'edit_device',
                              reason: "Autentique-se para editar o dispositivo",
                            );
                            if (!ok) return;

                            final confirmar = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => Dialog(
                                insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 8,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFB8860B), Color(0xFF5D4037)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                          FontAwesomeIcons.trashCan,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Text(
                                        'Confirmar remoção',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF3E2723),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Tem certeza que deseja desconectar este dispositivo?\n'
                                        'Essa ação apagará todas as configurações.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          height: 1.5,
                                          color: Color(0xFF5D4037),
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                side: BorderSide(
                                                  color: Colors.brown.shade400.withOpacity(0.5),
                                                  width: 1.3,
                                                ),
                                              ),
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: Text(
                                                'Cancelar',
                                                style: TextStyle(
                                                  color: Colors.brown.shade700,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                backgroundColor: Colors.redAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                shadowColor: Colors.redAccent.withOpacity(0.3),
                                                elevation: 4,
                                              ),
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Desconectar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
                              Navigator.pop(context, true);

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
