import 'dart:io';
import 'package:Jukefy/view/artist_description.dart';
import 'package:flutter/material.dart';
import 'package:Jukefy/database/artist_dao.dart';
import '../model/artist.dart';
import '../view/add_artist.dart';

class ArtistListWidget extends StatefulWidget {
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

  @override
  State<ArtistListWidget> createState() => _ArtistListWidgetState();
}

class _ArtistListWidgetState extends State<ArtistListWidget> {
  Widget _construirImagemArtista(String path) {
    if (path.isEmpty) {
      return Container(
        width: 55,
        height: 55,
        color: Colors.grey[800],
        child: const Icon(Icons.person, color: Colors.white),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _iconeErro(),
      );
    } else {
      return Image.file(
        File(path),
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _iconeErro(),
      );
    }
  }

  Widget _iconeErro() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey[800],
      child: const Icon(Icons.broken_image, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.artists.isEmpty) {
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
      itemCount: widget.artists.length,
      itemBuilder: (context, index) {
        final artist = widget.artists[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _construirImagemArtista(artist.imagePath),
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
                if (widget.showEditButton)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddArtist(artist: artist),
                        ),
                      );
                      if (widget.onArtistUpdated != null) {
                        widget.onArtistUpdated!();
                      }
                    },
                  ),
                if (widget.showDeleteButton)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await ArtistDao.instance.remove(artist);
                      if (widget.onArtistDeleted != null) {
                        widget.onArtistDeleted!();
                      }
                    },
                  ),
              ],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistDescription(artist: artist),
                ),
              );

              if (widget.onArtistUpdated != null) {
                widget.onArtistUpdated!();
              }
            },
          ),
        );
      },
    );
  }
}
