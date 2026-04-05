// =============================================================================
// gradient_icon.dart
//
// Ícone com gradiente aplicado via ShaderMask.
// Usado na barra de navegação inferior para destacar o item selecionado.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

/// Ícone que aplica um [gradient] quando [isSelected] é true; cinza caso contrário.
///
/// Usa [ShaderMask] para sobrepor o gradiente ao ícone branco subjacente.
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Gradient gradient; // Alterado para Gradient
  final bool isSelected;

  const GradientIcon({
    required this.icon,
    this.size = 24.0,
    required this.gradient,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSelected){
      return Icon(
        icon,
        size: size,
        color: Colors.grey[400],
      );
    }
    return ShaderMask(
      shaderCallback: (bounds) {
        // Cria um Shader a partir do LinearGradient
        return gradient.createShader(bounds);
      },
      child: Icon(
        icon,
        size: size,
        color: Colors.white, // A cor deve ser branca para o gradiente aparecer
      ),
    );
  }
}
