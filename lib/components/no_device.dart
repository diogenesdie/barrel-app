import 'package:flutter/material.dart';

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
