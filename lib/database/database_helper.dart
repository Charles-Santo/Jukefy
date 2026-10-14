import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  static const int _version = 3;
  static const String _dbName = 'owari_db.db';
  static const String unknownArtistName = 'Artista desconhecido';

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _version,
      onConfigure: _onConfigure,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createDb(Database db, int version) async {
    await _createTables(db);
  }

  /// Usa IF NOT EXISTS para servir tanto no onCreate quanto na migração
  /// de bancos criados pela versão anterior do app.
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS artists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        artisticName TEXT NOT NULL,
        description TEXT,
        imagePath TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        audioPath TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        idArtist INTEGER NOT NULL,
        durationInSeconds INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (idArtist) REFERENCES artists (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        imagePath TEXT,
        idUser INTEGER NOT NULL,
        FOREIGN KEY (idUser) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_songs(
        playlistId INTEGER NOT NULL,
        songId INTEGER NOT NULL,
        PRIMARY KEY (playlistId, songId),
        FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (songId) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<bool> _hasColumn(Database db, String table, String column) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((c) => c['name'] == column);
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    if (!await _hasColumn(db, table, column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Cria as tabelas que ainda não existiam (users, artists, playlists...).
    await _createTables(db);

    // Garante as colunas das tabelas artists e songs em bancos antigos.
    await _addColumnIfMissing(db, 'artists', 'description', 'TEXT');
    await _addColumnIfMissing(db, 'songs', 'title', "TEXT NOT NULL DEFAULT ''");
    await _addColumnIfMissing(
        db, 'songs', 'audioPath', "TEXT NOT NULL DEFAULT ''");
    await _addColumnIfMissing(
        db, 'songs', 'imagePath', "TEXT NOT NULL DEFAULT ''");
    await _addColumnIfMissing(db, 'songs', 'idArtist', 'INTEGER');
    await _addColumnIfMissing(
        db, 'songs', 'durationInSeconds', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(
        db, 'songs', 'isFavorite', 'INTEGER NOT NULL DEFAULT 0');

    // Músicas antigas não tinham artista: associa a um "Artista desconhecido".
    final orphans = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM songs WHERE idArtist IS NULL'),
        ) ??
        0;
    if (orphans > 0) {
      final existing = await db.query(
        'artists',
        where: 'artisticName = ?',
        whereArgs: [unknownArtistName],
        limit: 1,
      );
      final int artistId = existing.isNotEmpty
          ? existing.first['id'] as int
          : await db.insert('artists', {
              'name': unknownArtistName,
              'artisticName': unknownArtistName,
              'description': '',
              'imagePath': '',
            });
      await db.update(
        'songs',
        {'idArtist': artistId},
        where: 'idArtist IS NULL',
      );
    }
  }
}
