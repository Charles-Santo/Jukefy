import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:Jukefy/audio.dart';
import 'package:Jukefy/database/playlist_dao.dart';
import 'package:Jukefy/database/playlist_song_dao.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/view/add_playlist.dart';
import 'package:Jukefy/view/select_songs.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/song_list_widget.dart';

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

  int? _playingId;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
    _completeSub = appAudio.onPlayerComplete.listen((_) => _onSongComplete());
    _load();
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    if (_playingId != null) appAudio.stop();
    super.dispose();
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _playFrom(int index) async {
    var skipped = 0;

    while (index < _songs.length) {
      final song = _songs[index];

      if (File(song.audioPath).existsSync()) {
        if (mounted) setState(() => _playingId = song.id);
        try {
          await appAudio.play(DeviceFileSource(song.audioPath));
          if (skipped > 0 && mounted) {
            _showMessage('$skipped música(s) sem arquivo de áudio foram puladas.');
          }
          return;
        } catch (e) {
          debugPrint('Erro ao tocar ${song.title}: $e');
        }
      }

      skipped++;
      index++;
    }

    if (!mounted) return;
    setState(() => _playingId = null);
    if (skipped > 0) {
      _showMessage('Arquivo de áudio não encontrado. Edite a música e escolha o áudio novamente.');
    }
  }

  void _onSongComplete() {
    if (_playingId == null) return;
    final current = _songs.indexWhere((s) => s.id == _playingId);
    if (current < 0) {
      if (mounted) setState(() => _playingId = null);
      return;
    }
    _playFrom(current + 1);
  }

  Future<void> _stop() async {
    setState(() => _playingId = null);
    await appAudio.stop();
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

  @override
  Widget build(BuildContext context) {
    final description = (_playlist.description ?? '').trim();
    final isPlaying = _playingId != null;

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
                          onPressed: _songs.isEmpty
                              ? null
                              : (isPlaying ? _stop : () => _playFrom(0)),
                          icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(isPlaying ? 'Parar' : 'Tocar'),
                        ),
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
                          playingSongId: _playingId,
                          onSongTap: _playFrom,
                        ),
                ),
              ],
            ),
    );
  }
}
