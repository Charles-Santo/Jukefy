import 'package:flutter/material.dart';
import 'package:Jukefy/view/add_song.dart';
import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/model/song.dart';
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
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await SongDao.instance.getSongs();
    setState(() {
      _songs = songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                        MaterialPageRoute(
                          builder: (context) => const AddSong(),
                        ),
                      );
                      _loadSongs();
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
              onSongUpdated: _loadSongs,
              onSongDeleted: _loadSongs,
            ),
          ),
        ],
      ),
    );
  }
}