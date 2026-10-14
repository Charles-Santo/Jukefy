import 'package:flutter/material.dart';

import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/database/playlist_song_dao.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/widgets/app_image.dart';

/// Escolhe músicas (que ainda não estão na playlist) para adicionar.
class SelectSongs extends StatefulWidget {
  final Playlist playlist;
  const SelectSongs({super.key, required this.playlist});

  @override
  State<SelectSongs> createState() => _SelectSongsState();
}

class _SelectSongsState extends State<SelectSongs> {
  List<Song> _songs = [];
  Map<int, String> _artistNames = {};
  final Set<int> _selected = {};
  String _filter = '';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs =
        await PlaylistSongDao.instance.getSongsNotInPlaylist(widget.playlist.id!);
    final artists = await ArtistDao.instance.getAll();
    if (!mounted) return;
    setState(() {
      _songs = songs;
      _artistNames = {
        for (final a in artists)
          if (a.id != null) a.id!: a.artisticName,
      };
      _loading = false;
    });
  }

  List<Song> get _visible {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return _songs;
    return _songs.where((s) {
      final artist = (_artistNames[s.idArtist] ?? '').toLowerCase();
      return s.title.toLowerCase().contains(q) || artist.contains(q);
    }).toList();
  }

  Future<void> _confirm() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await PlaylistSongDao.instance
          .addSongsToPlaylist(widget.playlist.id!, _selected.toList());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar músicas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    decoration: const InputDecoration(
                      hintText: 'Filtrar por título ou artista',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            _songs.isEmpty
                                ? 'Todas as suas músicas já estão nesta playlist.'
                                : 'Nenhuma música encontrada.',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final song = visible[index];
                            final checked = _selected.contains(song.id);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selected.add(song.id!);
                                  } else {
                                    _selected.remove(song.id);
                                  }
                                });
                              },
                              secondary:
                                  AppImage(path: song.imagePath, size: 48),
                              title: Text(
                                song.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _artistNames[song.idArtist] ??
                                    'Artista desconhecido',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: (_selected.isEmpty || _saving) ? null : _confirm,
            child: Text(
              _selected.isEmpty
                  ? 'Selecione músicas'
                  : 'Adicionar (${_selected.length})',
            ),
          ),
        ),
      ),
    );
  }
}
