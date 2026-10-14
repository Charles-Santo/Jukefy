import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:Jukefy/model/song.dart';

enum RepeatMode { off, all, one }

String formatDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Player único do app: mantém a música tocando ao trocar de tela
/// e controla fila, shuffle e repeat.
///
/// Notifica (ChangeNotifier) quando muda a música, o estado play/pause,
/// shuffle ou repeat. A posição e a duração têm notifiers próprios,
/// para não reconstruir listas inteiras a cada segundo.
class PlayerService extends ChangeNotifier {
  PlayerService._();
  static final PlayerService instance = PlayerService._();

  final AudioPlayer _player = AudioPlayer();
  final Random _random = Random();
  bool _initialized = false;

  List<Song> _queue = [];
  int _index = -1;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.off;
  bool _isPlaying = false;
  final List<int> _history = [];

  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);

  List<Song> get queue => List.unmodifiable(_queue);
  Song? get currentSong =>
      (_index >= 0 && _index < _queue.length) ? _queue[_index] : null;
  bool get isPlaying => _isPlaying;
  bool get shuffle => _shuffle;
  RepeatMode get repeat => _repeat;

  void init() {
    if (_initialized) return;
    _initialized = true;

    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (playing != _isPlaying) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
    _player.onPositionChanged.listen((p) => position.value = p);
    _player.onDurationChanged.listen((d) => duration.value = d);
    _player.onPlayerComplete.listen((_) => _onComplete());
  }

  /// Toca [songs] a partir de [startIndex]. Retorna false se o arquivo
  /// de áudio da música escolhida não existir mais.
  Future<bool> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return false;
    }
    _queue = List.of(songs);
    _history.clear();
    _index = -1;
    return _playIndex(startIndex, pushHistory: false, skipMissing: false);
  }

  Future<bool> _playIndex(
    int index, {
    bool pushHistory = true,
    bool skipMissing = true,
    int direction = 1,
  }) async {
    if (_queue.isEmpty) return false;

    int i = index;
    int tries = 0;
    final maxTries = skipMissing ? _queue.length : 1;

    while (tries < maxTries) {
      final song = _queue[i];
      if (await File(song.audioPath).exists()) {
        if (pushHistory && _index >= 0) _history.add(_index);
        _index = i;
        position.value = Duration.zero;
        duration.value = Duration(seconds: song.duration);
        notifyListeners();
        try {
          await _player.play(DeviceFileSource(song.audioPath));
          return true;
        } catch (e) {
          debugPrint('Erro ao tocar música: $e');
        }
      }
      i = (i + direction) % _queue.length;
      if (i < 0) i += _queue.length;
      tries++;
    }
    return false;
  }

  Future<void> togglePlayPause() async {
    final song = currentSong;
    if (song == null) return;

    if (_isPlaying) {
      await _player.pause();
    } else if (_player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(DeviceFileSource(song.audioPath));
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;
    int target;
    if (_shuffle && _queue.length > 1) {
      do {
        target = _random.nextInt(_queue.length);
      } while (target == _index);
    } else {
      target = _index + 1;
      if (target >= _queue.length) target = 0;
    }
    await _playIndex(target, direction: 1);
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    // Se já passou de 3s, volta para o início da faixa atual.
    if (position.value.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_history.isNotEmpty) {
      final target = _history.removeLast();
      await _playIndex(target, pushHistory: false, direction: -1);
      return;
    }

    int target = _index - 1;
    if (target < 0) target = _queue.length - 1;
    await _playIndex(target, pushHistory: false, direction: -1);
  }

  Future<void> seek(Duration to) async {
    await _player.seek(to);
    position.value = to;
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void cycleRepeat() {
    _repeat = switch (_repeat) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    notifyListeners();
  }

  Future<void> _onComplete() async {
    if (_repeat == RepeatMode.one) {
      await _playIndex(_index, pushHistory: false, skipMissing: false);
      return;
    }

    if (_shuffle && _queue.length > 1) {
      await next();
      return;
    }

    final isLast = _index >= _queue.length - 1;
    if (!isLast) {
      await next();
    } else if (_repeat == RepeatMode.all) {
      await _playIndex(0, pushHistory: false);
    } else {
      _isPlaying = false;
      position.value = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _queue = [];
    _index = -1;
    _history.clear();
    _isPlaying = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    notifyListeners();
  }

  /// Remove da fila músicas que foram excluídas do banco.
  Future<void> removeSongsById(Iterable<int> ids) async {
    if (_queue.isEmpty) return;
    final idSet = ids.toSet();
    final current = currentSong;
    final removingCurrent = current?.id != null && idSet.contains(current!.id);

    if (removingCurrent) {
      await stop();
      return;
    }

    _queue.removeWhere((s) => s.id != null && idSet.contains(s.id));
    _history.clear();
    _index = current == null ? -1 : _queue.indexWhere((s) => s.id == current.id);
    notifyListeners();
  }
}
