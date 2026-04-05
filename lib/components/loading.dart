// =============================================================================
// loading.dart
//
// Widget de carregamento animado com três pontos pulsantes em gradiente.
// Exibe uma mensagem opcional abaixo dos pontos.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

/// Widget de carregamento com três pontos animados em gradiente do tema.
///
/// Cada ponto tem um delay progressivo criando efeito de onda.
/// Parâmetros opcionais:
///   - [mensagem]: texto exibido abaixo dos pontos
///   - [color]: cor base (padrão: cor primária do tema)
class Loading extends StatefulWidget {
  final String? mensagem;
  final Color? color;

  const Loading({super.key, this.mensagem, this.color});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? Theme.of(context).primaryColor;
    final primaryLight = Theme.of(context).primaryColorLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // Delay progressivo para cada bolinha
                  final progress = (_controller.value + (index * 0.33)) % 1.0;
                  
                  // Animação de bounce suave com amplitude reduzida
                  final dy = -6 * (1 - (progress - 0.5).abs() * 2);
                  
                  // Escala pulsante mais sutil
                  final scale = 1.0 + (0.15 * (1 - (progress - 0.5).abs() * 2));
                  
                  // Opacidade dinâmica
                  final opacity = 0.6 + (0.4 * (1 - (progress - 0.5).abs() * 2));

                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryLight.withOpacity(opacity),
                              primaryColor.withOpacity(opacity),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3 * opacity),
                              blurRadius: 6,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        if (widget.mensagem != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.mensagem!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}