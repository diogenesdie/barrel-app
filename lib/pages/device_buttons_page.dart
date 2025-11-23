import 'package:flutter/material.dart';
import 'package:smart_home/components/dialogs/edit_button_dialog.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/device_button.dart';
import 'package:smart_home/models/device_button_repository.dart';
import 'package:smart_home/services/button_sender_service.dart';
import 'package:smart_home/utils/devices_utils.dart';

class DeviceButtonsPage extends StatefulWidget {
  final Device device;

  const DeviceButtonsPage({super.key, required this.device});

  @override
  State<DeviceButtonsPage> createState() => _DeviceButtonsPageState();
}

class _DeviceButtonsPageState extends State<DeviceButtonsPage> {
  final repo = DeviceButtonRepository();
  final sender = ButtonSenderService();

  List<DeviceButton> buttons = [];
  bool loading = true;
  bool readMode = false;

  @override
  void initState() {
    super.initState();
    loadButtons();
  }

  Future<void> loadButtons() async {
    try {
      final local = await repo.getButtonsForDevice(widget.device.id);
      if (local.isNotEmpty) {
        setState(() {
          buttons = local;
          loading = false;
        });
        return;
      }

      final remote = await repo.fetchFromDevice(widget.device.ip, widget.device.id, true);

      setState(() {
        buttons = remote;
        loading = false;
      });
    } catch (e) {
      print("Erro ao carregar botões: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Não foi possível sincronizar os botões"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => loading = false);
    }
  }

  void onPress(DeviceButton b) async {
    await sender.sendButton(
      buttonName: b.originalName,
      device: widget.device,
    );
  }

  void onEdit(DeviceButton b) async {
    await showDialog(
      context: context,
      builder: (_) => EditButtonDialog(button: b),
    );
    setState(() {});
  }

  Future<void> clearButtons() async {
    try {
      await sender.sendCommand(device: widget.device, command: "clear_codes");
      await repo.deleteAllFromDevice(widget.device.id);

      setState(() {
        buttons = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Todos os botões foram apagados do dispositivo"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("Erro ao limpar: $e");
    }
  }

  Future<void> toggleReadMode() async {
    try {
      if (readMode) {
        await sender.sendCommand(device: widget.device, command: "read_mode_stop");
      } else {
        await sender.sendCommand(device: widget.device, command: "read_mode");
      }

      setState(() {
        readMode = !readMode;
      });
    } catch (e) {
      print("Erro no modo leitura: $e");
    }
  }

  Future<void> syncButtons() async {
    try {
      final remote = await repo.fetchFromDevice(
        widget.device.ip,
        widget.device.id,
        false,
      );

      final local = await repo.getButtonsForDevice(widget.device.id);

      final Map<String, DeviceButton> localMap = {for (var b in local) b.originalName: b};

      final Map<String, DeviceButton> remoteMap = {for (var b in remote) b.originalName: b};

      for (var r in remote) {
        if (!localMap.containsKey(r.originalName)) {
          await repo.insertButton(r);
        }
      }

      for (var l in local) {
        if (!remoteMap.containsKey(l.originalName)) {
          await repo.deleteButton(l.id);
        }
      }

      final finalList = await repo.getButtonsForDevice(widget.device.id);

      setState(() {
        buttons = finalList;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sincronização concluída"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("Erro ao sincronizar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Não foi possível sincronizar os botões"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildIcon(DeviceButton b) {
    if (b.icon.isEmpty) return const SizedBox.shrink();

    // 1) Ícones FontAwesome ou Material FIXOS
    final faIcon = buttonsIcons[b.icon];
    if (faIcon != null) {
      return Icon(faIcon, size: 28, color: Colors.white);
    }

    // 2) fallback
    return const Icon(Icons.help_outline, color: Colors.white, size: 26);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.device.name),
        actions: [
          // SINCRONIZAR
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blueAccent),
            tooltip: "Sincronizar botões",
            onPressed: syncButtons,
          ),

          // LIMPAR
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: "Apagar todos os botões",
            onPressed: clearButtons,
          ),

          // MODO LEITURA
          IconButton(
            icon: Icon(
              readMode ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: readMode ? Colors.greenAccent : Colors.grey,
            ),
            tooltip: readMode ? "Desativar modo leitura" : "Ativar modo leitura",
            onPressed: toggleReadMode,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
              ),
              itemCount: buttons.length,
              itemBuilder: (c, i) {
                final b = buttons[i];
                return GestureDetector(
                  onLongPress: () => onEdit(b),
                  onTap: () => onPress(b),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(b.color),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (b.icon.isNotEmpty) _buildIcon(b),
                          const SizedBox(height: 6),
                          Text(
                            b.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
