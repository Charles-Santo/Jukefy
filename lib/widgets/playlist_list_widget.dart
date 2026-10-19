import 'package:flutter/material.dart';

import 'package:Jukefy/database/playlist_dao.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:Jukefy/view/add_playlist.dart';
import 'package:Jukefy/view/playlist_detail.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/confirm_dialog.dart';

class PlaylistListWidget extends StatelessWidget {
  final List<Playlist> playlists;

  final Map<int, int> counts;
  final VoidCallback onChanged;

  const PlaylistListWidget({
    super.key,
    required this.playlists,
    required this.counts,
    required this.onChanged,
  });

  Future<void> _delete(BuildContext context, Playlist playlist) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir playlist',
      message:
          'Deseja excluir "${playlist.title}"? As músicas continuam na sua biblioteca.',
    );
    if (!confirmed) return;
    await PlaylistDao.instance.remove(playlist);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma playlist criada.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final total = counts[playlist.id] ?? 0;
        final description = (playlist.description ?? '').trim();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: AppImage(
              path: playlist.imagePath,
              size: 55,
              icon: Icons.queue_music,
            ),
            title: Text(
              playlist.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              description.isEmpty
                  ? '$total música(s)'
                  : '$total música(s) • $description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPlaylist(playlist: playlist),
                      ),
                    );
                    onChanged();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(context, playlist),
                ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetail(playlist: playlist),
                ),
              );
              onChanged();
            },
          ),
        );
      },
    );
  }
}
