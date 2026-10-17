import 'package:flutter/material.dart';

import 'package:Jukefy/model/user.dart';
import 'package:Jukefy/session.dart';
import 'package:Jukefy/view/artists_viewer.dart';
import 'package:Jukefy/view/favorite_songs.dart';
import 'package:Jukefy/view/library.dart';
import 'package:Jukefy/view/profile.dart';
import 'package:Jukefy/view/songs_viewer.dart';
import 'package:Jukefy/widgets/app_image.dart';
import 'package:Jukefy/widgets/option_card.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _indiceAtual = 1;

  void _aoTocarNoItem(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final telas = <Widget>[
      const SongsViewer(),
      ConteudoHome(onOpenLibrary: () => _aoTocarNoItem(2)),
      const Library(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jukefy',
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        actions: [
          ValueListenableBuilder<User?>(
            valueListenable: Session.currentUser,
            builder: (context, user, _) {
              return IconButton(
                tooltip: 'Meu perfil',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
                icon: AppImage(
                  path: user?.imagePath,
                  size: 32,
                  circular: true,
                  icon: Icons.person,
                ),
              );
            },
          ),
        ],
      ),
      body: telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: scheme.primary,
        unselectedItemColor: scheme.secondaryContainer,
        selectedItemColor: scheme.onPrimary,
        currentIndex: _indiceAtual,
        onTap: _aoTocarNoItem,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Songs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}

class ConteudoHome extends StatelessWidget {
  final VoidCallback onOpenLibrary;

  const ConteudoHome({super.key, required this.onOpenLibrary});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ValueListenableBuilder<User?>(
          valueListenable: Session.currentUser,
          builder: (context, user, _) {
            final firstName = (user?.name ?? '').trim().split(' ').first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                firstName.isEmpty ? 'Olá!' : 'Olá, $firstName!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: OptionCard(
                title: 'Artists',
                subtitle: 'Your Artists',
                icon: Icons.music_video,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArtistsViewer(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OptionCard(
                title: 'Playlists',
                subtitle: 'Your playlists',
                icon: Icons.playlist_play,
                onTap: onOpenLibrary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OptionCard(
          title: 'Your Favorites',
          subtitle: 'Songs you love',
          icon: Icons.star,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoriteSongs(),
              ),
            );
          },
        ),
      ],
    );
  }
}
