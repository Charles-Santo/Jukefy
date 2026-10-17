import 'package:flutter/material.dart';
import '../model/song.dart';
import '../database/song_dao.dart';
import '../widgets/song_list_widget.dart';

class FavoriteSongs extends StatefulWidget {
  const FavoriteSongs({super.key});

  @override
  State<FavoriteSongs> createState() => _FavoriteSongsState();
}

class _FavoriteSongsState extends State<FavoriteSongs> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _carregarMusicas();
  }

  void _carregarMusicas() {
    _songsFuture = SongDao.instance.getFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Favorites"),
      ),
      body: FutureBuilder<List<Song>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Nenhum dado encontrado."));
          }

          final songs = snapshot.data!;

          return SongListWidget(
            songs: songs,
            onFavoriteChanged: () {
              setState(() {
                _carregarMusicas();
              });
            },
          );
        },
      ),
    );
  }
}
