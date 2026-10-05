import 'package:flutter/material.dart';
import 'package:Jukefy/view/library.dart';
import 'package:Jukefy/view/songs_viewer.dart';
import 'package:Jukefy/widgets/option_card.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  int _indiceAtual = 1;

  
  final List<Widget> _telas = [
    const SongsViewer(),
    const ConteudoHome(),
    const LibrarySong()
    
  ];
  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
 
      appBar: AppBar(
        title: Text(
          'Jukefy',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: _telas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.primary, 
        unselectedItemColor: Theme.of(context).colorScheme.secondaryContainer,
        selectedItemColor: Theme.of(context).colorScheme.onPrimary,
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
            icon: Icon(Icons.library_add),
            label: 'Library',
            
          ),
        ],
      ),
    );
  }
void _aoTocarNoItem(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }
  
  }


class ConteudoHome extends StatelessWidget {
  const ConteudoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return  ListView(
        
        padding: const EdgeInsets.all(16.0),
        children: [
          
          Row(
            children: [
              Expanded(
                child: OptionCard(
                  
                  title: 'Playing now',
                  subtitle: 'Your queue',
                  icon: Icons.music_video,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OptionCard(
                  
                  title: 'Playlists',
                  subtitle: 'Genre',
                  icon: Icons.playlist_play,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          OptionCard(
            
            title: 'Your Favorites',
            subtitle: 'Aura Farm',
            icon: Icons.star,
            onTap: () {},
          ),
        ],
      );
  }
}