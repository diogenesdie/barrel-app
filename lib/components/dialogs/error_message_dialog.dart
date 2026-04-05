// =============================================================================
// error_message_dialog.dart
//
// Dialog de erro amigável exibido quando a configuração de um dispositivo falha.
// Exibe um ícone animado (pulsante) e a mensagem de erro com animação de fade.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

// Terceiros
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Dialog de erro amigável com ícone animado e [message] personalizada.
class FriendlyErrorDialog extends StatefulWidget {
  final String message;

  const FriendlyErrorDialog({
    super.key,
    required this.message,
  });

  @override
  State<FriendlyErrorDialog> createState() => _FriendlyErrorDialogState();
}

class _FriendlyErrorDialogState extends State<FriendlyErrorDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        const Color.fromARGB(255, 240, 210, 140),
        Theme.of(context).primaryColorLight,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: const FaIcon(
                  FontAwesomeIcons.faceFrown,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                widget.message,
                key: ValueKey(widget.message),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColorLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Entendi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
