import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

class _DeviceConfigDialogState extends State<DeviceConfigDialog> with TickerProviderStateMixin {
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
    } else if (msg.toLowerCase().contains("credenciais")) {
      return FontAwesomeIcons.wifi;
    } else if (msg.toLowerCase().contains("ip")) {
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

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 220, 179, 76),
                Theme.of(context).primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulse,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: FaIcon(
                    currentIcon,
                    key: ValueKey(currentIcon),
                    size: 60,
                    color: Colors.white,
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
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // Barra de progresso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColorLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
