import 'package:Jukefy/database/database_helper.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistDao {
  PlaylistDao._();
  static final PlaylistDao instance = PlaylistDao._();

  Future<List<Playlist>> getAll() async {
    Database db = await DatabaseHelper.instance.database;
    var playlists = await db.query('playlists', orderBy: 'id DESC');
    return playlists.isNotEmpty
        ? playlists.map((item) => Playlist.fromMap(item)).toList()
        : [];
  }

  Future<List<Playlist>> getByUser(int userId) async {
    Database db = await DatabaseHelper.instance.database;
    var playlists = await db.query(
      'playlists',
      where: 'idUser = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return playlists.isNotEmpty
        ? playlists.map((item) => Playlist.fromMap(item)).toList()
        : [];
  }

  Future<Playlist?> getById(int id) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query('playlists', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Playlist.fromMap(result.first);
    }
    return null;
  }

  Future<int> add(Playlist playlist) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('playlists', playlist.toMap());
  }

  Future<int> update(Playlist playlist) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.update(
      'playlists',
      playlist.toMap(),
      where: 'id = ?',
      whereArgs: [playlist.id],
    );
  }

  Future<int> remove(Playlist playlist) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete('playlists', where: 'id = ?', whereArgs: [playlist.id]);
  }
}