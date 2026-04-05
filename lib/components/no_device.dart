// =============================================================================
// no_device.dart
//
// Widget de estado vazio exibido quando não há dispositivos cadastrados.
// Suporta callback [onTap] para guiar o usuário ao fluxo de adição.
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

/// Exibe um card de estado vazio com ícone e texto padrão.
///
/// [onTap] é chamado quando o usuário toca no card (ex.: abrir tela de adição).
Widget noDevice({Function? onTap}) {
  return GestureDetector(
      child: SizedBox(
        width: double.infinity,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.devices_other_outlined, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  "Nenhum dispositivo adicionado",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Seus dispositivos aparecerão aqui",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      });
}
