import 'package:flutter/material.dart';
import 'package:smart_home/components/no_device.dart';
import 'package:smart_home/pages/auth_page.dart';

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
  // final List<DeviceItem> _devices = [
  //   DeviceItem(id: '1', name: 'Alimentador da sala', type: DeviceType.feeder, isFavorite: true, state: 'on'),
  //   DeviceItem(id: '2', name: 'Portão da casa', type: DeviceType.rfControl, isFavorite: false, state: 'off'),
  // ];
  final List<DeviceItem> _devices = [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final maxCardWidth = isLandscape ? 720.0 : 520.0;

        return Scaffold(
          body: SafeArea(
            child: _devices.isNotEmpty
                ? Center(
                    child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxCardWidth),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                          itemCount: _devices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final d = _devices[index];
                            return _DeviceCard(
                              device: d,
                              onFavorite: () => setState(() => d.isFavorite = !d.isFavorite),
                              onOpen: () async {
                                final updated = await Navigator.push<DeviceItem>(
                                  context,
                                  MaterialPageRoute(builder: (_) => DeviceEditPage(device: d.copy())),
                                );
                                if (updated != null) {
                                  setState(() {
                                    final idx = _devices.indexWhere((e) => e.id == updated.id);
                                    if (idx >= 0) _devices[idx] = updated;
                                  });
                                }
                              },
                            );
                          },
                        )),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: noDevice(),
                  ),
          ),
        );
      },
    );
  }
}

enum DeviceType { rfControl, feeder, unknown }

class DeviceItem {
  String id;
  String name;
  DeviceType type;
  bool isFavorite;
  String state;

  DeviceItem({
    required this.id,
    required this.name,
    required this.type,
    required this.isFavorite,
    required this.state,
  });

  DeviceItem copy() => DeviceItem(
        id: id,
        name: name,
        type: type,
        isFavorite: isFavorite,
        state: state,
      );
}

class _DeviceCard extends StatelessWidget {
  final DeviceItem device;
  final VoidCallback onFavorite;
  final VoidCallback onOpen;

  const _DeviceCard({
    required this.device,
    required this.onFavorite,
    required this.onOpen,
  });

  IconData _iconForType(DeviceType t) {
    switch (t) {
      case DeviceType.feeder:
        return Icons.pets;
      case DeviceType.rfControl:
        return Icons.settings_remote;
      default:
        return Icons.device_unknown;
    }
  }

  String _typeLabel(DeviceType t) {
    switch (t) {
      case DeviceType.feeder:
        return 'Alimentador';
      case DeviceType.rfControl:
        return 'Controle RF';
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
                          const SizedBox(width: 8),
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          Text(
                            'Estado: ${device.state}',
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
  final DeviceItem device;

  const DeviceEditPage({super.key, required this.device});

  @override
  State<DeviceEditPage> createState() => _DeviceEditPageState();
}

class _DeviceEditPageState extends State<DeviceEditPage> {
  late TextEditingController _nameCtrl;
  late DeviceType _type;
  late String _state;
  late IconData _selectedIcon;

  final Map<DeviceType, List<IconData>> _iconOptions = {
    DeviceType.rfControl: [
      Icons.settings_remote,
      Icons.garage,
      Icons.radio,
      Icons.wifi,
    ],
    DeviceType.feeder: [
      Icons.pets,
      Icons.restaurant,
      Icons.rice_bowl,
      Icons.local_dining,
      Icons.fastfood,
    ],
    DeviceType.unknown: [
      Icons.device_unknown,
      Icons.question_mark,
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
    _type = widget.device.type;
    _state = widget.device.state;
    _selectedIcon = _iconOptions[_type]!.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final maxCardWidth = isLandscape ? 520.0 : 420.0;

    return Scaffold(
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
                                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.grey.shade200,
                                    border: Border.all(
                                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 32,
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
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
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              onPressed: () {
                                final updated = widget.device
                                  ..name = _nameCtrl.text.trim()
                                  ..type = _type
                                  ..state = _state;
                                Navigator.pop(context, updated);
                              },
                              child: const Text('Salvar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
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
    );
  }
}
