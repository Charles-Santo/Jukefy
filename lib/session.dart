import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Jukefy/audio.dart';
import 'package:Jukefy/database/user_dao.dart';
import 'package:Jukefy/model/user.dart';

class Session {
  Session._();

  static const String _sessionKey = 'logged_user_id';
  static const String _salt = 'jukefy_v1_salt';

  static final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  static User? get user => currentUser.value;

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode('$_salt:$password')).toString();
  }

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id == null) return;

    final restored = await UserDao.instance.getById(id);
    if (restored == null) {
      await prefs.remove(_sessionKey);
      return;
    }
    currentUser.value = restored;
  }

  static Future<void> _save(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id!);
    currentUser.value = user;
  }

  static Future<String?> login(String email, String password) async {
    try {
      final found = await UserDao.instance.login(
        email.trim().toLowerCase(),
        hashPassword(password),
      );
      if (found == null) return 'E-mail ou senha incorretos.';
      await _save(found);
      return null;
    } catch (e) {
      return 'Erro ao entrar: $e';
    }
  }

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? imagePath,
  }) async {
    try {
      final normalized = email.trim().toLowerCase();
      if (await UserDao.instance.getByEmail(normalized) != null) {
        return 'Já existe uma conta com esse e-mail.';
      }

      final id = await UserDao.instance.add(
        User(
          name: name.trim(),
          email: normalized,
          password: hashPassword(password),
          imagePath: (imagePath == null || imagePath.isEmpty) ? null : imagePath,
        ),
      );

      final created = await UserDao.instance.getById(id);
      if (created == null) return 'Não foi possível criar a conta.';
      await _save(created);
      return null;
    } catch (e) {
      return 'Erro ao cadastrar: $e';
    }
  }

  static Future<void> updateProfile(User updated) async {
    await UserDao.instance.update(updated);
    final fresh = await UserDao.instance.getById(updated.id!);
    if (fresh != null) currentUser.value = fresh;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await appAudio.stop();
    currentUser.value = null;
  }
}
