import 'package:Jukefy/database/artist_dao.dart';
import 'package:Jukefy/model/artist.dart';
import 'package:Jukefy/view/add_artist.dart';
import 'package:Jukefy/widgets/artist_list_widget.dart';
import 'package:Jukefy/widgets/option_card.dart';
import 'package:flutter/material.dart';

class ArtistsViewer extends StatefulWidget {
  const ArtistsViewer({super.key});

  @override
  State<ArtistsViewer> createState() => _ArtistViewerState();
}

class _ArtistViewerState extends State<ArtistsViewer> {
  late Future<List<Artist>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    _carregarArtistas();
  }

  void _carregarArtistas() {
    _artistsFuture = ArtistDao.instance.getAll(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Artists"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OptionCard(
                  title: 'Add Artist',
                  subtitle: 'Register your favorite Artist',
                  icon: Icons.emoji_people_sharp,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddArtist(),
                      ),
                    );
                    setState(() {
                      _carregarArtistas();
                    });
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Artist>>(
              future: _artistsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Erro ao carregar: ${snapshot.error}"));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text("Nenhum dado encontrado."));
                }

                final artists = snapshot.data!;

                if (artists.isEmpty) {
                  return const Center(child: Text("Nenhum artista cadastrado."));
                }

                return ArtistListWidget(
                  artists: artists,
                  showDeleteButton: true, 
                  showEditButton: true, 
                  onArtistDeleted: () {
                    setState(() {
                      _carregarArtistas();
                    });
                  }, 
                  onArtistUpdated: () {
                    setState(() {
                      _carregarArtistas();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}