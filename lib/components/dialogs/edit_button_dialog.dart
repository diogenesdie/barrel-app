import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smart_home/models/device_button.dart';

class EditButtonDialog extends StatefulWidget {
  final DeviceButton button;

  const EditButtonDialog({super.key, required this.button});

  @override
  State<EditButtonDialog> createState() => _EditButtonDialogState();
}

class _EditButtonDialogState extends State<EditButtonDialog> {
  late TextEditingController labelCtrl;

  int selectedColor = 0xFF1E1E1E;
  String selectedIcon = "";

  // 🔥 Paleta elegante Barrel
  final List<int> _colors = [
    0xFF1E1E1E,
    0xFF263238,
    0xFF2D5BFF,
    0xFF00BFA5,
    0xFFFF5722,
    0xFFE63247,
    0xFFFFC400,
    0xFF8E24AA,
  ];

  // 🔥 FontAwesome + MaterialIcons organizados
  final Map<String, IconData> _icons = {
    "power": FontAwesomeIcons.powerOff,
    "tv": FontAwesomeIcons.tv,
    "volume_up": FontAwesomeIcons.volumeHigh,
    "volume_down": FontAwesomeIcons.volumeLow,
    "play": FontAwesomeIcons.play,
    "pause": FontAwesomeIcons.pause,
    "forward": FontAwesomeIcons.forward,
    "back": FontAwesomeIcons.backward,
    "light": FontAwesomeIcons.lightbulb,
    "fan": FontAwesomeIcons.fan,
    "snow": FontAwesomeIcons.snowflake,
    "wifi": FontAwesomeIcons.wifi,
    "bolt": FontAwesomeIcons.bolt,
    "bars": FontAwesomeIcons.bars,
    "circle": Icons.circle, // fallback Material
    "stop": FontAwesomeIcons.stop,
    "x": FontAwesomeIcons.xmark,
    "empty": Icons.block,
  };

  @override
  void initState() {
    super.initState();
    labelCtrl = TextEditingController(text: widget.button.label);
    selectedColor = widget.button.color;
    selectedIcon = widget.button.icon;
  }

  void save() async {
    widget.button.label = labelCtrl.text.trim();
    widget.button.color = selectedColor;
    widget.button.icon = selectedIcon;
    await widget.button.save();

    Navigator.pop(context, widget.button);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /** HEADER **/
            const Text(
              "Editar Botão",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            /** PREVIEW **/
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(selectedColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _icons[selectedIcon] ?? Icons.circle,
                    color: Colors.white,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labelCtrl.text.isEmpty ? "Prévia" : labelCtrl.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /** LABEL **/
            TextField(
              controller: labelCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nome",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 22),

            /** COLORS **/
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cor",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colors.map((c) => _colorCircle(c)).toList(),
              ),
            ),

            const SizedBox(height: 25),

            /** ICONS **/
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Ícone",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 100,
              child: GridView.count(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: _icons.keys.map((key) => _iconTile(key)).toList(),
              ),
            ),

            const SizedBox(height: 20),

            /** ACTIONS **/
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Salvar"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _colorCircle(int color) {
    bool active = selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        width: active ? 34 : 28,
        height: active ? 34 : 28,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Color(color).withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
      ),
    );
  }

  Widget _iconTile(String key) {
    bool active = selectedIcon == key;

    return GestureDetector(
      onTap: () => setState(() => selectedIcon = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: active ? Colors.blueAccent.withOpacity(0.2) : Colors.white10,
          border: Border.all(
            color: active ? Colors.blueAccent : Colors.white24,
          ),
        ),
        child: Center(
          child: Icon(
            _icons[key],
            color: active ? Colors.blueAccent : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
