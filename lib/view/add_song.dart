import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../model/song.dart';
import '../model/artist.dart';
import '../database/song_dao.dart';
import '../database/artist_dao.dart';

class AddSong extends StatefulWidget {
  final Song? song;
  const AddSong({super.key, this.song});

  @override
  State<AddSong> createState() => _AddSongState();
}

class _AddSongState extends State<AddSong> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();

  int? _selectedArtistId;
  int _durationInSeconds = 0;
  bool _isFavorite = false;
  String? _audioPath;

  List<Artist> _artists = [];
  bool _isLoadingArtists = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();

    if (widget.song != null) {
      _titleController.text = widget.song!.title;
      _selectedArtistId = widget.song!.idArtist;
      _durationInSeconds = widget.song!.duration;
      _imagePathController.text = widget.song!.imagePath;
      _isFavorite = widget.song!.isFavorite;
      _audioPath = widget.song!.audioPath;
    }
  }

  Future<void> _loadArtists() async {
    try {
      final list = await ArtistDao.instance.getAll();
      setState(() {
        _artists = list;
        _isLoadingArtists = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingArtists = false;
      });
    }
  }

  Future<void> _selecionarImagemEpegarCaminho() async {
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (resultado != null && resultado.files.single.path != null) {
      setState(() {
        _imagePathController.text = resultado.files.single.path!;
      });
    }
  }

  Future<void> _selecionarAudioEpegarCaminho() async {
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (resultado != null && resultado.files.single.path != null) {
      String caminhoEscolhido = resultado.files.single.path!;

      setState(() {
        _audioPath = caminhoEscolhido;
      });

      try {
        final player = AudioPlayer();
        await player.setSourceDeviceFile(caminhoEscolhido);
        Duration? duracao = await player.getDuration();

        if (duracao != null) {
          setState(() {
            _durationInSeconds = duracao.inSeconds;
          });
        }

        await player.dispose();
      } catch (e) {
        debugPrint('Erro ao obter a duração: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song == null ? "Novo Song" : "Alterando o Song"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      body: _isLoadingArtists
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: "Título"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Entre com o título da música';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<int>(
                        value: _selectedArtistId,
                        decoration: const InputDecoration(labelText: "Artista"),
                        items: _artists.map((artist) {
                          return DropdownMenuItem<int>(
                            value: artist.id,
                            child: Text(artist.artisticName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedArtistId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecione um artista';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _selecionarAudioEpegarCaminho,
                            icon: const Icon(Icons.audiotrack),
                            label: const Text("Escolher Áudio"),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _audioPath != null
                                  ? "${_audioPath!.split('/').last} (${_durationInSeconds}s)"
                                  : "Nenhum áudio selecionado",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imagePathController,
                              decoration: const InputDecoration(
                                labelText: "Caminho da Capa (URL ou Local)",
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe ou selecione a capa';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.image_search,
                              size: 30,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            onPressed: _selecionarImagemEpegarCaminho,
                            tooltip: 'Buscar na Galeria',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      SwitchListTile(
                        title: const Text("Favoritar música?"),
                        value: _isFavorite,
                        onChanged: (bool value) {
                          setState(() {
                            _isFavorite = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_audioPath == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Por favor, selecione um arquivo de áudio!",
                                  ),
                                ),
                              );
                              return;
                            }

                            Song song = Song(
                              id: widget.song?.id,
                              title: _titleController.text,
                              idArtist: _selectedArtistId!,
                              duration: _durationInSeconds,
                              audioPath: _audioPath!,
                              imagePath: _imagePathController.text,
                              isFavorite: _isFavorite,
                            );

                            if (widget.song == null) {
                              await SongDao.instance.add(song);
                            } else {
                              await SongDao.instance.update(song);
                            }

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Song salvo com sucesso!"),
                              ),
                            );

                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Salvar"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }
}