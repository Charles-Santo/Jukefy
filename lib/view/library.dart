import 'package:flutter/material.dart';

import 'package:Jukefy/database/playlist_dao.dart';
import 'package:Jukefy/database/playlist_song_dao.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:Jukefy/session.dart';
import 'package:Jukefy/view/add_playlist.dart';
import 'package:Jukefy/widgets/option_card.dart';
import 'package:Jukefy/widgets/playlist_list_widget.dart';

class _LibraryData {
  final List<Playlist> playlists;
  final Map<int, int> counts;
  _LibraryData(this.playlists, this.counts);
}

/// Aba Library: playlists do usuário logado.
class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  late Future<_LibraryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LibraryData> _load() async {
    final userId = Session.user!.id!;
    final playlists = await PlaylistDao.instance.getByUser(userId);
    final counts = await PlaylistSongDao.instance.countByPlaylist();
    return _LibraryData(playlists, counts);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: OptionCard(
            title: 'New Playlist',
            subtitle: 'Create a playlist with your songs',
            icon: Icons.playlist_add,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPlaylist()),
              );
              _reload();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<_LibraryData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text("Erro ao carregar: ${snapshot.error}"),
                );
              } else if (!snapshot.hasData) {
                return const Center(child: Text("Nenhum dado encontrado."));
              }

              final data = snapshot.data!;
              return PlaylistListWidget(
                playlists: data.playlists,
                counts: data.counts,
                onChanged: _reload,
              );
            },
          ),
        ),
      ],
    );
  }
}
