import 'package:flutter/material.dart';

class ShareTarget {
  final String label;
  final Color color;
  final IconData icon;

  const ShareTarget({
    required this.label,
    required this.color,
    required this.icon,
  });

  static const all = [
    ShareTarget(label: 'WhatsApp', color: Color(0xFF25D366), icon: Icons.chat_bubble),
    ShareTarget(label: 'Correo',   color: Color(0xFF0ea5e9), icon: Icons.email),
    ShareTarget(label: 'Drive',    color: Color(0xFFf59e0b), icon: Icons.cloud_upload),
    ShareTarget(label: 'Imprimir', color: Color(0xFF64748b), icon: Icons.print),
    ShareTarget(label: 'Enlace',   color: Color(0xFF8b5cf6), icon: Icons.link),
    ShareTarget(label: 'Más',      color: Color(0xFF94a3b8), icon: Icons.more_horiz),
  ];
}
