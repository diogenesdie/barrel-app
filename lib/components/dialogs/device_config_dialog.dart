// =============================================================================
// device_config_dialog.dart
//
// Dialog de progresso para o fluxo de configuração BLE de um novo dispositivo.
// Exibe os [steps] do processo e executa [onProcess] de forma assíncrona,
// atualizando a mensagem exibida via callback.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Dialog animado que exibe o progresso da configuração BLE de um novo dispositivo.
///
/// [steps]: lista de mensagens de passo exibidas sequencialmente.
/// [onProcess]: função assíncrona que executa a configuração e chama o callback
///              fornecido para atualizar o passo atual exibido.
class DeviceConfigDialog extends StatefulWidget {
  final List<String> steps;
  final Future<void> Function(Function(String) updateStep) onProcess;

  const DeviceConfigDialog({
    super.key,
    required this.steps,
    required this.onProcess,
  });

  @override
  State<DeviceConfigDialog> createState() => _DeviceConfigDialogState();
}

class _DeviceConfigDialogState extends State<DeviceConfigDialog>
    with TickerProviderStateMixin {
  String currentMessage = "";
  bool finished = false;
  IconData currentIcon = FontAwesomeIcons.microchip;

  late AnimationController _pulseController;
  late Animation<double> _pulse;
  int currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    currentMessage = widget.steps.first;

    // animação de pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // roda o processo
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.onProcess(updateStep);
      if (mounted) {
        setState(() {
          finished = true;
          currentIcon = FontAwesomeIcons.checkCircle;
          currentStepIndex = widget.steps.length - 1;

          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop(true);
          });
        });
        _pulseController.stop();
      }
    });
  }

  void updateStep(String msg) {
    final index = widget.steps.indexOf(msg);
    setState(() {
      currentMessage = msg;
      currentStepIndex = index >= 0 ? index : currentStepIndex;
      currentIcon = _getIconForStep(msg);
    });
  }

  IconData _getIconForStep(String msg) {
    if (msg.toLowerCase().contains("conectando")) {
      return FontAwesomeIcons.bluetoothB;
    } else if (msg.toLowerCase().contains("wi-fi")) {
      return FontAwesomeIcons.wifi;
    } else if (msg.toLowerCase().contains("dispositivo")) {
      return FontAwesomeIcons.networkWired;
    } else if (msg.toLowerCase().contains("conclu")) {
      return FontAwesomeIcons.checkCircle;
    }
    return FontAwesomeIcons.microchip;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentStepIndex + 1) / widget.steps.length;

    // gradient reutilizável
    final gradient = LinearGradient(
      colors: [
        const Color.fromARGB(255, 220, 179, 76),
        Theme.of(context).primaryColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white, // fundo branco
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulse,
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      gradient.createShader(bounds), // gradient nos ícones
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: FaIcon(
                      currentIcon,
                      key: ValueKey(currentIcon),
                      size: 60,
                      color: Colors.white, // necessário pro ShaderMask
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  currentMessage,
                  key: ValueKey(currentMessage),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black, // texto preto
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // Barra de progresso com gradient
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: gradient,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
