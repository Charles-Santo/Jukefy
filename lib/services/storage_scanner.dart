import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class ScannedAudio {
  final String path;
  final String name;
  final String folder;

  ScannedAudio({required this.path})
      : name = p.basenameWithoutExtension(path),
        folder = p.basename(p.dirname(path));
}

/// Procura arquivos de áudio no armazenamento do dispositivo.
class StorageScanner {
  static const Set<String> audioExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.wav',
    '.flac',
    '.ogg',
    '.opus',
    '.wma',
  };

  static const List<String> defaultDirectories = [
    '/storage/emulated/0/Music',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/Downloads',
    '/storage/emulated/0/Recordings',
    '/storage/emulated/0/Podcasts',
  ];

  /// Pede permissão de leitura de áudio.
  /// Android 13+: READ_MEDIA_AUDIO. Antes disso: READ_EXTERNAL_STORAGE.
  static Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return true;

    var status = await Permission.audio.request();
    if (status.isGranted || status.isLimited) return true;

    status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<List<ScannedAudio>> scan(List<String> directories) async {
    final found = <String, ScannedAudio>{};

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      try {
        if (!await dir.exists()) continue;

        await for (final entity in dir
            .list(recursive: true, followLinks: false)
            .handleError((_) {})) {
          if (entity is! File) continue;
          final path = entity.path;
          if (path.contains('${Platform.pathSeparator}.')) continue; // ocultos
          final ext = p.extension(path).toLowerCase();
          if (audioExtensions.contains(ext)) {
            found[path] = ScannedAudio(path: path);
          }
        }
      } catch (_) {
        // Pasta sem acesso: ignora e segue para a próxima.
      }
    }

    final list = found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
