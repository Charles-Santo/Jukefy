import 'package:flutter/material.dart';

import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/model/artist.dart';
import 'package:Jukefy/services/player_service.dart';
import 'package:Jukefy/view/now_playing.dart';
import 'package:Jukefy/widgets/app_image.dart';

/// Barra com a música atual. Some sozinha quando nada está tocando.
class MiniPlayer extends StatelessWidget {
  /// Use true em telas empilhadas (sem BottomNavigationBar embaixo).
  final bool useSafeArea;

  const MiniPlayer({super.key, this.useSafeArea = false});

  @override
  Widget build(BuildContext context) {
    final player = PlayerService.instance;

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final song = player.currentSong;
        if (song == null) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;

        final bar = Material(
          color: scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NowPlayingPage()),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<Duration>(
                  valueListenable: player.position,
                  builder: (context, pos, _) {
                    final totalMs = player.duration.value.inMilliseconds > 0
                        ? player.duration.value.inMilliseconds
                        : song.duration * 1000;
                    final value = totalMs > 0
                        ? (pos.inMilliseconds / totalMs).clamp(0.0, 1.0)
                        : 0.0;
                    return LinearProgressIndicator(value: value, minHeight: 2);
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      AppImage(path: song.imagePath, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            FutureBuilder<Artist?>(
                              future: ArtistDao.instance.getById(song.idArtist),
                              builder: (context, snap) => Text(
                                snap.data?.artisticName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: player.previous,
                      ),
                      IconButton(
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: player.togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: player.next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        return useSafeArea ? SafeArea(top: false, child: bar) : bar;
      },
    );
  }
}
