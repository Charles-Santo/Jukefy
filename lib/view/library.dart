import 'package:flutter/material.dart';
import '../model/song.dart';
import '../database/song_dao.dart';
import '../widgets/song_list_widget.dart';

class LibrarySong extends StatefulWidget {
  const LibrarySong({super.key});

  @override
  State<LibrarySong> createState() => _LibrarySongState();
}

class _LibrarySongState extends State<LibrarySong> {
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _carregarMusicas();
  }

  void _carregarMusicas() {
 
    _songsFuture = SongDao.instance.getSongs(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          
          return SongListWidget(songs: songs);
        },
      ),
    );
  }
}