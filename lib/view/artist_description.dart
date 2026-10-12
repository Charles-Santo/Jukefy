import 'dart:io';
import 'package:flutter/material.dart';
import 'package:Jukefy/model/artist.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/widgets/song_list_widget.dart';

class ArtistDescription extends StatefulWidget {
  final Artist artist;

  const ArtistDescription({super.key, required this.artist});

  @override
  State<ArtistDescription> createState() => _ArtistDescriptionState();
}

class _ArtistDescriptionState extends State<ArtistDescription> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _carregarMusicasDoArtista();
  }

  void _carregarMusicasDoArtista() {
    _songsFuture = SongDao.instance.getByArtist(widget.artist.id!);
  }

  Widget _construirImagemArtista(String path) {
    if (path.isEmpty) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 70, color: Colors.white),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CircleAvatar(
        radius: 70,
        backgroundImage: NetworkImage(path),
        onBackgroundImageError: (_, __) {},
      );
    } else {
      return CircleAvatar(
        radius: 70,
        backgroundImage: FileImage(File(path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist.artisticName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: ClipOval(
              child: _construirImagemArtista(widget.artist.imagePath),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.artist.artisticName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.artist.name,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              widget.artist.description.isNotEmpty
                  ? widget.artist.description
                  : "Nenhuma descrição informada.",
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 30, thickness: 1, indent: 24, endIndent: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Músicas do Artista",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Song>>(
              future: _songsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Erro ao carregar músicas: ${snapshot.error}"));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text("Nenhuma música encontrada."));
                }

                final songs = snapshot.data!;

                return SongListWidget(
                  songs: songs,
                  showDeleteButton: true,
                  showEditButton: true,
                  onSongDeleted: () {
                    setState(() {
                      _carregarMusicasDoArtista();
                    });
                  },
                  onSongUpdated: () {
                    setState(() {
                      _carregarMusicasDoArtista();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}