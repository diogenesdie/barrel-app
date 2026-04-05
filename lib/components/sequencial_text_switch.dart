// =============================================================================
// sequencial_text_switch.dart
//
// Widget que anima a troca de texto com fade + slide suave.
// Usado nos cards de dispositivo para mostrar estado ("Ligado" / "Desligado")
// sem flicker visual quando o estado muda rapidamente.
//
// Nota: o nome do arquivo mantém o typo original por compatibilidade com imports existentes.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

/// Exibe [text] com animação de fade e slide ao mudar o valor.
///
/// Ao receber um novo [text], apaga o texto atual com fade-out (400ms) e
/// exibe o novo com fade-in + slide-up, evitando troca brusca.
class SequentialTextSwitcher extends StatefulWidget {
  final String text;

  const SequentialTextSwitcher({super.key, required this.text});

  @override
  State<SequentialTextSwitcher> createState() => _SequentialTextSwitcherState();
}

class _SequentialTextSwitcherState extends State<SequentialTextSwitcher> {
  String _visibleText = "";
  String _pendingText = "";

  @override
  void initState() {
    super.initState();
    _visibleText = widget.text;
  }

  @override
  void didUpdateWidget(covariant SequentialTextSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _visibleText) {
      _pendingText = widget.text;

      setState(() => _visibleText = "");
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted && _pendingText.isNotEmpty) {
          setState(() {
            _visibleText = _pendingText;
            _pendingText = "";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 12,
    );

    return SizedBox(
      height: (textStyle.fontSize ?? 12) * 1.2, // altura fixa aproximada
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _visibleText.isEmpty
            ? const SizedBox(key: ValueKey('empty'))
            : Text(
                _visibleText,
                key: ValueKey(_visibleText),
                style: textStyle,
              ),
      ),
    );
  }
}
