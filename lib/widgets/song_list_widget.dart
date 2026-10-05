import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Jukefy/database/song_dao.dart';
import '../model/song.dart';
import '../view/add_song.dart';

class SongListWidget extends StatefulWidget {
  final List<Song> songs;
  final bool showEditButton;
  final bool showDeleteButton;
  final VoidCallback? onSongUpdated;
  final VoidCallback? onSongDeleted;

  const SongListWidget({
    super.key,
    required this.songs,
    this.showEditButton = false,
    this.showDeleteButton = false,
    this.onSongUpdated,
    this.onSongDeleted,
  });

  @override
  State<SongListWidget> createState() => _SongListWidgetState();
}

class _SongListWidgetState extends State<SongListWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _construirImagemCapa(String path) {
    if (path.isEmpty) {
      return Container(
        width: 55,
        height: 55,
        color: Colors.grey[800],
        child: const Icon(Icons.music_note, color: Colors.white),
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

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: _construirImagemCapa(song.imagePath),
            ),
            title: Row(
              children: [
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
                  onPressed: () {
                    setState(() {
                      song.isFavorite = !song.isFavorite;
                    });
                    SongDao.instance.update(song);
                  },
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(child: Text("${song.artist} • ${song.genre} • ${song.duration}s")),
              ],
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
                          builder: (context) => AddSong(song: song),
                        ),
                      );
                      if (widget.onSongUpdated != null) {
                        widget.onSongUpdated!();
                      }
                    },
                  ),
                if (widget.showDeleteButton)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await SongDao.instance.remove(song);
                      if (widget.onSongDeleted != null) {
                        widget.onSongDeleted!();
                      }
                    },
                  ),
              ],
            ),
            onTap: () async {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Tocando: ${song.title}"),
                  duration: const Duration(seconds: 2),
                ),
              );

              try {
                await _audioPlayer.play(DeviceFileSource(song.audioPath));
              } catch (e) {
                print("Erro ao tocar música: $e");
              }
            },
          ),
        );
      },
    );
  }
}
