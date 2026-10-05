
import 'package:Jukefy/database/database_helper.dart';
import 'package:Jukefy/model/song.dart';
import 'package:sqflite/sqflite.dart';

class SongDao {
  SongDao._();
  static final SongDao instance = SongDao._();

  Future<List<Song>> getSongs() async {
    Database db = await DatabaseHelper.instance.database;

    var songs = await db.query('songs', orderBy: 'id DESC');

    List<Song> songList = songs.isNotEmpty
        ? songs.map((item) => Song.fromMap(item)).toList()
        : [];

    return songList;
  }

  Future<int> add(Song newSong) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('songs', newSong.toMap());
  }

  Future<int> remove(Song song) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete('songs', where: 'id = ?', whereArgs: [song.id]);
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
}
