import 'package:Jukefy/database/database_helper.dart';
import 'package:Jukefy/model/artist.dart';
import 'package:sqflite/sqflite.dart';

class ArtistDao {
  ArtistDao._();
  static final ArtistDao instance = ArtistDao._();

  Future<List<Artist>> getAll() async {
    Database db = await DatabaseHelper.instance.database;
    var artists = await db.query('artists', orderBy: 'artisticName ASC');
    return artists.isNotEmpty
        ? artists.map((item) => Artist.fromMap(item)).toList()
        : [];
  }

  Future<Artist?> getById(int id) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query('artists', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Artist.fromMap(result.first);
    }
    return null;
  }

  /// Retorna o id do "Artista desconhecido", criando-o se necessário.
  /// Usado nas músicas importadas do armazenamento, que ainda não têm artista.
  Future<int> getOrCreateUnknown() async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query(
      'artists',
      where: 'artisticName = ?',
      whereArgs: [DatabaseHelper.unknownArtistName],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first['id'] as int;
    return await db.insert('artists', {
      'name': DatabaseHelper.unknownArtistName,
      'artisticName': DatabaseHelper.unknownArtistName,
      'description': '',
      'imagePath': '',
    });
  }

  Future<int> add(Artist artist) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('artists', artist.toMap());
  }

  Future<int> update(Artist artist) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.update(
      'artists',
      artist.toMap(),
      where: 'id = ?',
      whereArgs: [artist.id],
    );
  }

  Future<int> remove(Artist artist) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete('artists', where: 'id = ?', whereArgs: [artist.id]);
  }
}
