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
  final List<int> _selected = [];
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
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar músicas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                
                Expanded(
                  child: _songs.isEmpty
                      ? const Center(
                          child: Text(
                            'Todas as suas músicas já estão nesta playlist.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            final order = _selected.indexOf(song.id!);
                            final checked = order >= 0;
                            return ListTile(
                              selected: checked,
                              leading:
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
                              trailing: checked
                                  ? CircleAvatar(
                                      radius: 14,
                                      child: Text('${order + 1}'),
                                    )
                                  : const Icon(Icons.radio_button_unchecked),
                              onTap: () {
                                setState(() {
                                  if (checked) {
                                    _selected.remove(song.id!);
                                  } else {
                                    _selected.add(song.id!);
                                  }
                                });
                              },
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