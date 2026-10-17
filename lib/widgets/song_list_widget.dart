import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:Jukefy/audio.dart';
import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/database/playlist_song_dao.dart';
import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/view/add_song.dart';
import 'package:Jukefy/widgets/add_to_playlist_sheet.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/confirm_dialog.dart';

enum _SongAction { addToPlaylist, removeFromPlaylist, edit, delete }

class SongListWidget extends StatefulWidget {
  final List<Song> songs;
  final bool showEditButton;
  final bool showDeleteButton;
  final VoidCallback? onSongUpdated;
  final VoidCallback? onSongDeleted;
  final VoidCallback? onFavoriteChanged;

  final int? playlistId;
  final VoidCallback? onRemovedFromPlaylist;

  final void Function(int index)? onSongTap;

  final int? playingSongId;

  const SongListWidget({
    super.key,
    required this.songs,
    this.showEditButton = false,
    this.showDeleteButton = false,
    this.onSongUpdated,
    this.onSongDeleted,
    this.onFavoriteChanged,
    this.playlistId,
    this.onRemovedFromPlaylist,
    this.onSongTap,
    this.playingSongId,
  });

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  Map<int, String> _artistNames = {};

  @override
  void initState() {
    super.initState();
    _loadArtistNames();
  }

  @override
  void didUpdateWidget(covariant SongListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.songs, widget.songs)) {
      _loadArtistNames();
    }
  }

  Future<void> _loadArtistNames() async {
    final artists = await ArtistDao.instance.getAll();
    if (!mounted) return;
    setState(() {
      _artistNames = {
        for (final a in artists)
          if (a.id != null) a.id!: a.artisticName,
      };
    });
  }

  String _formatarDuracao(int segundosTotais) {
    final minutos = segundosTotais ~/ 60;
    final segundos = (segundosTotais % 60).toString().padLeft(2, '0');
    return '$minutos:$segundos';
  }

  Future<void> _toggleFavorite(Song song) async {
    setState(() {
      song.isFavorite = !song.isFavorite;
    });
    await SongDao.instance.update(song);
    widget.onFavoriteChanged?.call();
  }

  Future<void> _playSingle(Song song) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (!File(song.audioPath).existsSync()) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Arquivo de áudio não encontrado. Edite a música e escolha o áudio novamente.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text('Tocando: ${song.title}'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await appAudio.play(DeviceFileSource(song.audioPath));
    } catch (e) {
      debugPrint('Erro ao tocar música: $e');
    }
  }

  Future<void> _onAction(_SongAction action, Song song) async {
    switch (action) {
      case _SongAction.addToPlaylist:
        await showAddToPlaylistSheet(context, song);
        break;

      case _SongAction.removeFromPlaylist:
        if (widget.playlistId == null || song.id == null) return;
        await PlaylistSongDao.instance
            .removeSongFromPlaylist(widget.playlistId!, song.id!);
        widget.onRemovedFromPlaylist?.call();
        break;

      case _SongAction.edit:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddSong(song: song)),
        );
        widget.onSongUpdated?.call();
        break;

      case _SongAction.delete:
        final confirmed = await confirmDialog(
          context,
          title: 'Excluir música',
          message: 'Deseja excluir "${song.title}"? Ela também sairá das playlists.',
        );
        if (!confirmed) return;
        await SongDao.instance.remove(song);
        widget.onSongDeleted?.call();
        break;
    }
  }

  List<PopupMenuEntry<_SongAction>> _menuItems() {
    PopupMenuItem<_SongAction> item(
      _SongAction value,
      IconData icon,
      String label, {
      Color? color,
    }) {
      return PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );
    }

    return [
      item(_SongAction.addToPlaylist, Icons.playlist_add, 'Adicionar à playlist'),
      if (widget.playlistId != null)
        item(_SongAction.removeFromPlaylist, Icons.playlist_remove,
            'Remover da playlist'),
      if (widget.showEditButton)
        item(_SongAction.edit, Icons.edit, 'Editar', color: Colors.blue),
      if (widget.showDeleteButton)
        item(_SongAction.delete, Icons.delete, 'Excluir', color: Colors.red),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.songs.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma música encontrada.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: widget.songs.length,
      itemBuilder: (context, index) {
        final song = widget.songs[index];
        final isPlaying =
            widget.playingSongId != null && widget.playingSongId == song.id;
        final artistName = _artistNames[song.idArtist] ?? 'Artista desconhecido';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            selected: isPlaying,
            contentPadding: const EdgeInsets.all(8.0),
            leading: AppImage(path: song.imagePath, size: 55),
            title: Row(
              children: [
                if (isPlaying) ...[
                  const Icon(Icons.graphic_eq, size: 18),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    song.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: song.isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleFavorite(song),
                ),
              ],
            ),
            subtitle: Text(
              "$artistName • ${_formatarDuracao(song.duration)}",
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<_SongAction>(
              onSelected: (action) => _onAction(action, song),
              itemBuilder: (_) => _menuItems(),
            ),
            onTap: () {
              final onTap = widget.onSongTap;
              if (onTap != null) {
                onTap(index);
              } else {
                _playSingle(song);
              }
            },
          ),
        );
      },
    );
  }
}
