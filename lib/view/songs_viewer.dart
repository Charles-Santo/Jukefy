import 'dart:async';

import 'package:flutter/material.dart';

import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/view/add_artist.dart';
import 'package:Jukefy/view/add_song.dart';
import 'package:Jukefy/view/storage_search.dart';
import '../widgets/option_card.dart';
import '../widgets/song_list_widget.dart';

class SongsViewer extends StatefulWidget {
  const SongsViewer({super.key});

  @override
  State<SongsViewer> createState() => _SongsViewerState();
}

class _SongsViewerState extends State<SongsViewer> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Song> _songs = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _carregarMusicas();
  }

  Future<void> _carregarMusicas() async {
    final songs = _query.trim().isEmpty
        ? await SongDao.instance.getSongs()
        : await SongDao.instance.search(_query);
    if (!mounted) return;
    setState(() {
      _songs = songs;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = value;
      _carregarMusicas();
    });
  }

  Future<void> _abrirBuscaNoArmazenamento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StorageSearch()),
    );
    _carregarMusicas();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OptionCard(
                  title: 'Add Song',
                  subtitle: 'Register a new song',
                  icon: Icons.my_library_music,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddSong()),
                    );
                    _carregarMusicas();
                  },
                ),
              ),
              Expanded(
                child: OptionCard(
                  title: 'Add Artist',
                  subtitle: 'Register your favorite Artist',
                  icon: Icons.emoji_people_sharp,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddArtist(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por título ou artista',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _query = '';
                              _carregarMusicas();
                            },
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Buscar músicas no armazenamento',
                icon: const Icon(Icons.folder_open),
                onPressed: _abrirBuscaNoArmazenamento,
              ),
            ],
          ),
        ),
        Expanded(
          child: SongListWidget(
            songs: _songs,
            showEditButton: true,
            showDeleteButton: true,
            onSongUpdated: _carregarMusicas,
            onSongDeleted: _carregarMusicas,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
