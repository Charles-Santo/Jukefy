import 'package:flutter/material.dart';

import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/model/artist.dart';
import 'package:Jukefy/view/add_artist.dart';
import 'package:Jukefy/view/artist_description.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/confirm_dialog.dart';

class ArtistListWidget extends StatelessWidget {
  final List<Artist> artists;
  final bool showEditButton;
  final bool showDeleteButton;
  final VoidCallback? onArtistUpdated;
  final VoidCallback? onArtistDeleted;

  const ArtistListWidget({
    super.key,
    required this.artists,
    this.showEditButton = false,
    this.showDeleteButton = false,
    this.onArtistUpdated,
    this.onArtistDeleted,
  });

  Future<void> _delete(BuildContext context, Artist artist) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir artista',
      message:
          'Deseja excluir "${artist.artisticName}"? Todas as músicas desse artista também serão excluídas.',
    );
    if (!confirmed || artist.id == null) return;

    await ArtistDao.instance.remove(artist);
    onArtistDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum artista encontrado.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: AppImage(
              path: artist.imagePath,
              size: 55,
              icon: Icons.person,
            ),
            title: Text(
              artist.artisticName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              artist.name,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showEditButton)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddArtist(artist: artist),
                        ),
                      );
                      onArtistUpdated?.call();
                    },
                  ),
                if (showDeleteButton)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _delete(context, artist),
                  ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistDescription(artist: artist),
                ),
              );
              onArtistUpdated?.call();
            },
          ),
        );
      },
    );
  }
}
