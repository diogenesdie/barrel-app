// lib/pages/devices_page.dart
import 'package:flutter/material.dart';
import 'package:smart_home/pages/auth_page.dart';

/// --- reutilizáveis (importe de onde já estiverem no seu projeto) ---
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
  // MOCK: substitua por sua fonte (API/SharedPreferences)
  final List<DeviceItem> _devices = [
    DeviceItem(id: '1', name: 'Lâmpada Sala', type: DeviceType.light, isFavorite: true, state: 'on'),
    DeviceItem(id: '2', name: 'Tomada Aquário', type: DeviceType.plug, isFavorite: false, state: 'off'),
    DeviceItem(id: '3', name: 'Ventilador Quarto', type: DeviceType.fan, isFavorite: false, state: 'off'),
    DeviceItem(id: '4', name: 'Garagem', type: DeviceType.garage, isFavorite: true, state: 'closed'),
    DeviceItem(id: '5', name: 'Termostato', type: DeviceType.thermostat, isFavorite: false, state: '22°C'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final maxCardWidth = isLandscape ? 720.0 : 520.0;

        return Scaffold(
          body: SafeArea(
            child: Center(
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
                        // abre edição
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Modelo simples
enum DeviceType { light, plug, fan, garage, thermostat, unknown }

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

/// Card do dispositivo
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
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.plug:
        return Icons.power_outlined;
      case DeviceType.fan:
        return Icons.toys; // ventilador estilizado
      case DeviceType.garage:
        return Icons.garage;
      case DeviceType.thermostat:
        return Icons.thermostat;
      default:
        return Icons.device_unknown;
    }
  }

  String _typeLabel(DeviceType t) {
    switch (t) {
      case DeviceType.light:
        return 'Lâmpada';
      case DeviceType.plug:
        return 'Tomada';
      case DeviceType.fan:
        return 'Ventilador';
      case DeviceType.garage:
        return 'Garagem';
      case DeviceType.thermostat:
        return 'Termostato';
      default:
        return 'Dispositivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final grad = appGradient(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen, // abre edição (tap no card todo, exceto estrela)
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
                // ícone com fundo em degradê
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
                // textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                // botão estrela com degradê
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

/// Estrela com degradê (toggle de favorito)
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
            // anel sutil
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

/// Tela de edição (layout no mesmo estilo)
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.device.name);
    _type = widget.device.type;
    _state = widget.device.state;
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
            gradient: appGradient(context),
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
                      TextField(
                        controller: _nameCtrl,
                        decoration: _dec('Nome do dispositivo'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<DeviceType>(
                        value: _type,
                        decoration: _dec('Tipo'),
                        items: DeviceType.values
                            .where((e) => e != DeviceType.unknown)
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_label(t)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v ?? _type),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: TextEditingController(text: _state),
                        onChanged: (v) => _state = v,
                        decoration: _dec('Estado (texto livre)'),
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

  String _label(DeviceType t) {
    switch (t) {
      case DeviceType.light:
        return 'Lâmpada';
      case DeviceType.plug:
        return 'Tomada';
      case DeviceType.fan:
        return 'Ventilador';
      case DeviceType.garage:
        return 'Garagem';
      case DeviceType.thermostat:
        return 'Termostato';
      default:
        return 'Desconhecido';
    }
  }
}
