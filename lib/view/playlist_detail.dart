import 'package:flutter/material.dart';

import 'package:Jukefy/database/playlist_dao.dart';
import 'package:Jukefy/database/playlist_song_dao.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/services/player_service.dart';
import 'package:Jukefy/view/add_playlist.dart';
import 'package:Jukefy/view/select_songs.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/mini_player.dart';
import 'package:Jukefy/widgets/song_list_widget.dart';

/// Músicas pertencentes a uma playlist.
class PlaylistDetail extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetail({super.key, required this.playlist});

  @override
  State<PlaylistDetail> createState() => _PlaylistDetailState();
}

class _PlaylistDetailState extends State<PlaylistDetail> {
  late Playlist _playlist;
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _load();
  }

  Future<void> _load() async {
    final fresh = await PlaylistDao.instance.getById(_playlist.id!);
    final songs = await PlaylistSongDao.instance.getSongsByPlaylist(_playlist.id!);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _playlist = fresh;
      _songs = songs;
      _loading = false;
    });
  }

  Future<void> _addSongs() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SelectSongs(playlist: _playlist)),
    );
    _load();
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddPlaylist(playlist: _playlist)),
    );
    _load();
  }

  Future<void> _playAll({bool shuffle = false}) async {
    if (_songs.isEmpty) return;
    final player = PlayerService.instance;
    if (shuffle != player.shuffle) player.toggleShuffle();
    final ok = await player.playQueue(_songs, 0);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo de áudio não encontrado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final description = (_playlist.description ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Editar playlist',
            icon: const Icon(Icons.edit),
            onPressed: _edit,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AppImage(
                        path: _playlist.imagePath,
                        size: 90,
                        radius: 12,
                        icon: Icons.queue_music,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _playlist.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(height: 4),
                            Text('${_songs.length} música(s)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _songs.isEmpty ? null : () => _playAll(),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Tocar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Aleatório',
                        onPressed: _songs.isEmpty
                            ? null
                            : () => _playAll(shuffle: true),
                        icon: const Icon(Icons.shuffle),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Adicionar músicas',
                        onPressed: _addSongs,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _songs.isEmpty
                      ? const Center(
                          child: Text(
                            'Esta playlist ainda não tem músicas.\nToque em + para adicionar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : SongListWidget(
                          songs: _songs,
                          playlistId: _playlist.id,
                          onRemovedFromPlaylist: _load,
                          onFavoriteChanged: () {},
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const MiniPlayer(useSafeArea: true),
    );
  }
}
