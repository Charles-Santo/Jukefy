import 'package:Jukefy/database/database_helper.dart';
import 'package:Jukefy/model/song.dart';
import 'package:sqflite/sqflite.dart';

class SongDao {
  SongDao._();
  static final SongDao instance = SongDao._();

  Future<List<Song>> getSongs() async {
    Database db = await DatabaseHelper.instance.database;
    var songs = await db.query('songs', orderBy: 'id DESC');
    return songs.isNotEmpty
        ? songs.map((item) => Song.fromMap(item)).toList()
        : [];
  }

  Future<Song?> getById(int id) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Song.fromMap(result.first);
    }
    return null;
  }

  Future<List<Song>> getByArtist(int artistId) async {
    Database db = await DatabaseHelper.instance.database;
    var songs = await db.query(
      'songs',
      where: 'idArtist = ?',
      whereArgs: [artistId],
      orderBy: 'title ASC',
    );
    return songs.isNotEmpty
        ? songs.map((item) => Song.fromMap(item)).toList()
        : [];
  }

  Future<List<Song>> getFavorites() async {
    Database db = await DatabaseHelper.instance.database;
    var songs = await db.query(
      'songs',
      where: 'isFavorite = 1',
      orderBy: 'title ASC',
    );
    return songs.isNotEmpty
        ? songs.map((item) => Song.fromMap(item)).toList()
        : [];
  }

  Future<int> add(Song newSong) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('songs', newSong.toMap());
  }

  Future<int> update(Song song) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<int> remove(Song song) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete('songs', where: 'id = ?', whereArgs: [song.id]);
  }
}