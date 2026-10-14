import 'package:flutter/material.dart';
import 'package:Jukefy/model/user.dart';
import 'package:Jukefy/services/auth_service.dart';
import 'package:Jukefy/services/player_service.dart';
import 'package:Jukefy/view/homepage.dart';
import 'package:Jukefy/view/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.restoreSession();
  PlayerService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jukefy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 175, 224),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Decide qual tela mostrar: login (sem usuário) ou homepage (com usuário).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        if (user == null) return const LoginPage();
        return Homepage(key: ValueKey(user.id));
      },
    );
  }
}
