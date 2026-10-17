import 'package:flutter/material.dart';

import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/view/add_artist.dart';
import 'package:Jukefy/view/add_song.dart';
import '../widgets/option_card.dart';
import '../widgets/song_list_widget.dart';

class SongsViewer extends StatefulWidget {
  const SongsViewer({super.key});

  @override
  State<SongsViewer> createState() => _SongsViewerState();
}

class _SongsViewerState extends State<SongsViewer> {
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _carregarMusicas();
  }

  Future<void> _carregarMusicas() async {
    final songs = await SongDao.instance.getSongs();
    if (!mounted) return;
    setState(() {
      _songs = songs;
    });
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
}