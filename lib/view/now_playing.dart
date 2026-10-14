import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/database/song_dao.dart';
import 'package:Jukefy/model/artist.dart';
import 'package:Jukefy/services/player_service.dart';
import 'package:Jukefy/widgets/app_image.dart';

/// Tela do player: capa, progresso e controles.
class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final PlayerService player = PlayerService.instance;
  double? _dragValue;

  void _showQueue() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Fila de reprodução',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListenableBuilder(
                listenable: player,
                builder: (context, _) {
                  final queue = player.queue;
                  final currentId = player.currentSong?.id;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final song = queue[index];
                      final isCurrent = song.id == currentId;
                      return ListTile(
                        selected: isCurrent,
                        leading: AppImage(path: song.imagePath, size: 40),
                        title: Text(song.title, overflow: TextOverflow.ellipsis),
                        trailing: isCurrent
                            ? const Icon(Icons.equalizer)
                            : null,
                        onTap: () => player.playQueue(queue, index),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final song = player.currentSong;
    if (song == null) return;
    setState(() {
      song.isFavorite = !song.isFavorite;
    });
    await SongDao.instance.update(song);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final coverSize = math.min(MediaQuery.of(context).size.width * 0.75, 320.0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tocando agora'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Fila',
            icon: const Icon(Icons.queue_music),
            onPressed: _showQueue,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: player,
        builder: (context, _) {
          final song = player.currentSong;
          if (song == null) {
            return const Center(child: Text('Nada tocando no momento.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  AppImage(
                    path: song.imagePath,
                    size: coverSize,
                    radius: 20,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            FutureBuilder<Artist?>(
                              future: ArtistDao.instance.getById(song.idArtist),
                              builder: (context, snap) => Text(
                                snap.data?.artisticName ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        iconSize: 30,
                        icon: Icon(
                          song.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: song.isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<Duration>(
                    valueListenable: player.position,
                    builder: (context, pos, _) {
                      final totalMs = player.duration.value.inMilliseconds > 0
                          ? player.duration.value.inMilliseconds
                          : song.duration * 1000;
                      final maxMs = totalMs > 0 ? totalMs.toDouble() : 1.0;
                      final current = (_dragValue ??
                              pos.inMilliseconds.toDouble())
                          .clamp(0.0, maxMs)
                          .toDouble();

                      return Column(
                        children: [
                          Slider(
                            value: current,
                            max: maxMs,
                            onChanged: (v) => setState(() => _dragValue = v),
                            onChangeEnd: (v) async {
                              await player
                                  .seek(Duration(milliseconds: v.toInt()));
                              if (mounted) setState(() => _dragValue = null);
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatDuration(
                                    Duration(milliseconds: current.toInt()))),
                                Text(formatDuration(
                                    Duration(milliseconds: totalMs))),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Aleatório',
                        icon: Icon(
                          Icons.shuffle,
                          color: player.shuffle ? scheme.primary : null,
                        ),
                        onPressed: player.toggleShuffle,
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: player.previous,
                      ),
                      IconButton.filled(
                        iconSize: 40,
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: player.togglePlayPause,
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next),
                        onPressed: player.next,
                      ),
                      IconButton(
                        tooltip: 'Repetir',
                        icon: Icon(
                          player.repeat == RepeatMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: player.repeat != RepeatMode.off
                              ? scheme.primary
                              : null,
                        ),
                        onPressed: player.cycleRepeat,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
