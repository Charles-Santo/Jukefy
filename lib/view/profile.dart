import 'package:flutter/material.dart';

import 'package:Jukefy/model/user.dart';
import 'package:Jukefy/services/auth_service.dart';
import 'package:Jukefy/view/register_user.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/confirm_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Sair',
      message: 'Deseja sair da sua conta?',
      confirmText: 'Sair',
    );
    if (!confirmed) return;

    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Excluir conta',
      message:
          'Sua conta e todas as suas playlists serão excluídas. Essa ação não pode ser desfeita.',
    );
    if (!confirmed) return;

    await AuthService.instance.deleteAccount();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ValueListenableBuilder<User?>(
        valueListenable: AuthService.instance.currentUser,
        builder: (context, user, _) {
          if (user == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: AppImage(
                  path: user.imagePath,
                  size: 120,
                  circular: true,
                  icon: Icons.person,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar perfil'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterUserPage(user: user),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () => _logout(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Excluir conta',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _deleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
