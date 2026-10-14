import 'dart:io';
import 'package:flutter/material.dart';

/// Imagem a partir de caminho local ou URL, com placeholder e tratamento de erro.
class AppImage extends StatelessWidget {
  final String? path;
  final double size;
  final IconData icon;
  final bool circular;
  final double radius;

  const AppImage({
    super.key,
    required this.path,
    required this.size,
    this.icon = Icons.music_note,
    this.circular = false,
    this.radius = 8,
  });

  Widget _placeholder(IconData iconData) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[800],
      child: Icon(iconData, color: Colors.white, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = path;
    Widget child;

    if (value == null || value.isEmpty) {
      child = _placeholder(icon);
    } else if (value.startsWith('http://') || value.startsWith('https://')) {
      child = Image.network(
        value,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
      );
    } else {
      child = Image.file(
        File(value),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
      );
    }

    return circular
        ? ClipOval(child: child)
        : ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
