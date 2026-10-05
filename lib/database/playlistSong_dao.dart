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
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> removeSongFromPlaylist(int playlistId, int songId) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete(
      'playlist_songs',
      where: 'playlistId = ? AND songId = ?',
      whereArgs: [playlistId, songId],
    );
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
}