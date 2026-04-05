// =============================================================================
// device_warning.dart
//
// Widget de aviso contextual com ícone, título e mensagem configuráveis.
// Semelhante ao [noDevice], mas para situações específicas (ex.: Wi-Fi 5GHz,
// sem permissão Bluetooth, grupo sem dispositivos).
// =============================================================================

// Flutter
import 'package:flutter/material.dart';

/// Exibe um card de aviso com [icon], [title] e [message] configuráveis.
///
/// [onTap] é chamado quando o usuário toca no card (ação contextual opcional).
Widget deviceWarning(String title, String message, IconData? icon, {Function? onTap}) {
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
              Icon(icon, size: 40, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
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
    },
  );
}
