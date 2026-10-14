import 'package:Jukefy/database/database_helper.dart';
import 'package:Jukefy/model/song.dart';
import 'package:Jukefy/model/playlistSong.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistSongDao {
  PlaylistSongDao._();
  static final PlaylistSongDao instance = PlaylistSongDao._();

  Future<int> addSongToPlaylist(int playlistId, int songId) async {
    Database db = await DatabaseHelper.instance.database;
    PlaylistSong relation = PlaylistSong(playlistId: playlistId, songId: songId);
    return await db.insert(
      'playlist_songs',
      relation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> addSongsToPlaylist(int playlistId, List<int> songIds) async {
    Database db = await DatabaseHelper.instance.database;
    Batch batch = db.batch();
    for (final songId in songIds) {
      batch.insert(
        'playlist_songs',
        PlaylistSong(playlistId: playlistId, songId: songId).toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<bool> isSongInPlaylist(int playlistId, int songId) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Song>> getSongsByPlaylist(int playlistId) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.songId
      WHERE ps.playlistId = ?
      ORDER BY s.title ASC
    ''', [playlistId]);

    return result.isNotEmpty
        ? result.map((item) => Song.fromMap(item)).toList()
        : [];
  }

  /// Músicas que ainda NÃO estão na playlist (para a tela de adicionar).
  Future<List<Song>> getSongsNotInPlaylist(int playlistId) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.rawQuery('''
      SELECT s.* FROM songs s
      WHERE s.id NOT IN (
        SELECT songId FROM playlist_songs WHERE playlistId = ?
      )
      ORDER BY s.title ASC
    ''', [playlistId]);

    return result.isNotEmpty
        ? result.map((item) => Song.fromMap(item)).toList()
        : [];
  }

  /// Quantidade de músicas por playlist: {playlistId: total}.
  Future<Map<int, int>> countByPlaylist() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.rawQuery('''
      SELECT playlistId, COUNT(*) AS total
      FROM playlist_songs
      GROUP BY playlistId
    ''');
    return {
      for (final row in result) row['playlistId'] as int: row['total'] as int,
    };
  }
}
