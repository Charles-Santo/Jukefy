import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Jukefy/database/user_dao.dart';
import 'package:Jukefy/model/user.dart';
import 'package:Jukefy/services/player_service.dart';

/// Controla o usuário logado (sessão persistente), login, cadastro e logout.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _sessionKey = 'logged_user_id';
  static const String _salt = 'jukefy_v1_salt';

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  User? get user => currentUser.value;

  /// Hash SHA-256 (com salt fixo do app). A senha nunca é salva em texto puro.
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode('$_salt:$password')).toString();
  }

  Future<void> restoreSession() async {
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

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id!);
    currentUser.value = user;
  }

  /// Retorna null em caso de sucesso, ou a mensagem de erro.
  Future<String?> login(String email, String password) async {
    try {
      final found = await UserDao.instance.login(
        email.trim().toLowerCase(),
        hashPassword(password),
      );
      if (found == null) return 'E-mail ou senha incorretos.';
      await _saveSession(found);
      return null;
    } catch (e) {
      return 'Erro ao entrar: $e';
    }
  }

  /// Cria a conta e já deixa o usuário logado.
  /// Retorna null em caso de sucesso, ou a mensagem de erro.
  Future<String?> register({
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
      await _saveSession(created);
      return null;
    } catch (e) {
      return 'Erro ao cadastrar: $e';
    }
  }

  /// Salva alterações do perfil do usuário logado.
  Future<void> updateProfile(User updated) async {
    await UserDao.instance.update(updated);
    final fresh = await UserDao.instance.getById(updated.id!);
    if (fresh != null) currentUser.value = fresh;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await PlayerService.instance.stop();
    currentUser.value = null;
  }

  /// Exclui a conta (as playlists do usuário são apagadas em cascata).
  Future<void> deleteAccount() async {
    final current = user;
    if (current != null) {
      await UserDao.instance.remove(current);
    }
    await logout();
  }
}
