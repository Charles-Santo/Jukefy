import 'package:Jukefy/database/database_helper.dart';
import 'package:Jukefy/model/user.dart';
import 'package:sqflite/sqflite.dart';

class UserDao {
  UserDao._();
  static final UserDao instance = UserDao._();

  Future<List<User>> getAll() async {
    Database db = await DatabaseHelper.instance.database;
    var users = await db.query('users', orderBy: 'id DESC');
    return users.isNotEmpty ? users.map((item) => User.fromMap(item)).toList() : [];
  }

  Future<User?> getById(int id) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<User?> login(String email, String password) async {
    Database db = await DatabaseHelper.instance.database;
    var result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  Future<int> add(User user) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<int> update(User user) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> remove(User user) async {
    Database db = await DatabaseHelper.instance.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
  }
}