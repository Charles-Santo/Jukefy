import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/services/storage_scanner.dart';

/// Função adicional: busca músicas no armazenamento do dispositivo
/// e importa as escolhidas para a biblioteca.
class StorageSearch extends StatefulWidget {
  const StorageSearch({super.key});

  @override
  State<StorageSearch> createState() => _StorageSearchState();
}

class _StorageSearchState extends State<StorageSearch> {
  List<ScannedAudio> _files = [];
  Set<String> _existing = {};
  final Set<String> _selected = {};

  String _filter = '';
  bool _scanning = false;
  bool _scanned = false;
  bool _permissionDenied = false;

  bool _importing = false;
  int _importDone = 0;
  int _importTotal = 0;

  Future<void> _runScan(List<String> directories) async {
    setState(() {
      _scanning = true;
      _permissionDenied = false;
    });

    final granted = await StorageScanner.ensurePermission();
    if (!granted) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _permissionDenied = true;
      });
      return;
    }

    final files = await StorageScanner.scan(directories);
    final existing = await SongDao.instance.getAllAudioPaths();
    if (!mounted) return;

    setState(() {
      _files = files;
      _existing = existing;
      _selected.clear();
      _scanning = false;
      _scanned = true;
    });
  }

  Future<void> _pickFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    await _runScan([dir]);
  }

  List<ScannedAudio> get _visible {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return _files;
    return _files
        .where((f) =>
            f.name.toLowerCase().contains(q) ||
            f.folder.toLowerCase().contains(q))
        .toList();
  }

  List<ScannedAudio> get _selectable =>
      _visible.where((f) => !_existing.contains(f.path)).toList();

  void _toggleAll() {
    final selectable = _selectable;
    final allSelected =
        selectable.isNotEmpty && selectable.every((f) => _selected.contains(f.path));
    setState(() {
      if (allSelected) {
        for (final f in selectable) {
          _selected.remove(f.path);
        }
      } else {
        for (final f in selectable) {
          _selected.add(f.path);
        }
      }
    });
  }

  Future<void> _import() async {
    if (_selected.isEmpty) return;

    final paths = _selected.toList();
    setState(() {
      _importing = true;
      _importDone = 0;
      _importTotal = paths.length;
    });

    final player = AudioPlayer();
    int imported = 0;

    try {
      final unknownArtistId = await ArtistDao.instance.getOrCreateUnknown();

      for (final path in paths) {
        final audio = _files.firstWhere((f) => f.path == path);

        int seconds = 0;
        try {
          await player.setSourceDeviceFile(path);
          final d =
              await player.getDuration().timeout(const Duration(seconds: 5));
          seconds = d?.inSeconds ?? 0;
        } catch (_) {
          // Mantém 0 se não conseguir ler a duração deste arquivo.
        }

        await SongDao.instance.add(
          Song(
            title: audio.name,
            idArtist: unknownArtistId,
            duration: seconds,
            audioPath: path,
            imagePath: '',
          ),
        );
        imported++;

        if (mounted) setState(() => _importDone = imported);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    } finally {
      await player.dispose();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$imported música(s) importada(s). Edite-as para definir o artista.',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final selectable = _selectable;
    final allSelected =
        selectable.isNotEmpty && selectable.every((f) => _selected.contains(f.path));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar no dispositivo'),
        actions: [
          if (_files.isNotEmpty && !_importing)
            IconButton(
              tooltip: allSelected ? 'Desmarcar todas' : 'Selecionar todas',
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
              onPressed: _toggleAll,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_scanning || _importing)
                        ? null
                        : () => _runScan(StorageScanner.defaultDirectories),
                    icon: const Icon(Icons.search),
                    label: const Text('Pastas padrão'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_scanning || _importing) ? null : _pickFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Escolher pasta'),
                  ),
                ),
              ],
            ),
          ),
          if (_files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                onChanged: (v) => setState(() => _filter = v),
                decoration: const InputDecoration(
                  hintText: 'Filtrar resultados por nome ou pasta',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          if (_importing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _importTotal == 0 ? null : _importDone / _importTotal,
                  ),
                  const SizedBox(height: 4),
                  Text('Importando $_importDone de $_importTotal...'),
                ],
              ),
            ),
          Expanded(child: _buildBody(visible)),
        ],
      ),
      bottomNavigationBar: _files.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed:
                      (_selected.isEmpty || _importing) ? null : _import,
                  child: Text(
                    _selected.isEmpty
                        ? 'Selecione músicas para importar'
                        : 'Importar (${_selected.length})',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(List<ScannedAudio> visible) {
    if (_scanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Procurando arquivos de áudio...'),
          ],
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Sem permissão para ler os arquivos de áudio do dispositivo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: openAppSettings,
                child: const Text('Abrir configurações'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_scanned) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Procure nas pastas padrão (Music, Download...) ou escolha uma pasta específica do aparelho.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(child: Text('Nenhum arquivo de áudio encontrado.'));
    }

    if (visible.isEmpty) {
      return const Center(child: Text('Nenhum resultado para o filtro.'));
    }

    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final file = visible[index];
        final alreadyAdded = _existing.contains(file.path);

        return CheckboxListTile(
          value: alreadyAdded ? true : _selected.contains(file.path),
          onChanged: (alreadyAdded || _importing)
              ? null
              : (value) {
                  setState(() {
                    if (value == true) {
                      _selected.add(file.path);
                    } else {
                      _selected.remove(file.path);
                    }
                  });
                },
          secondary: const Icon(Icons.audiotrack),
          title: Text(file.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            alreadyAdded ? '${file.folder} • já na biblioteca' : file.folder,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
