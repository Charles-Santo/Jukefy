import 'package:flutter/material.dart';

import 'package:Jukefy/database/playlist_dao.dart';
import 'package:Jukefy/database/playlist_song_dao.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/services/auth_service.dart';
import 'package:Jukefy/widgets/app_image.dart';

/// Mostra as playlists do usuário logado e adiciona [song] na escolhida.
Future<void> showAddToPlaylistSheet(BuildContext context, Song song) async {
  final user = AuthService.instance.user;
  if (user == null || song.id == null) return;

  final messenger = ScaffoldMessenger.of(context);
  final playlists = await PlaylistDao.instance.getByUser(user.id!);
  if (!context.mounted) return;

  if (playlists.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Crie uma playlist primeiro, na aba Library.'),
      ),
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Adicionar à playlist',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: playlists.map((playlist) {
                return ListTile(
                  leading: AppImage(
                    path: playlist.imagePath,
                    size: 40,
                    icon: Icons.queue_music,
                  ),
                  title: Text(playlist.title),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final already = await PlaylistSongDao.instance
                        .isSongInPlaylist(playlist.id!, song.id!);
                    if (already) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'A música já está em "${playlist.title}".',
                          ),
                        ),
                      );
                      return;
                    }
                    await PlaylistSongDao.instance
                        .addSongToPlaylist(playlist.id!, song.id!);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Adicionada a "${playlist.title}".'),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
