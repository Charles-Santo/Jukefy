import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../model/song.dart';
import '../model/artist.dart';
import '../database/song_dao.dart';
import '../database/artist_dao.dart';
import '../services/file_service.dart';
import 'add_artist.dart';

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
  bool _saving = false;

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
      if (!mounted) return;
      setState(() {
        _artists = list;
        _isLoadingArtists = false;
      });
    } catch (e) {
      if (!mounted) return;
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
        _durationInSeconds = 0;
      });

      // Se o título ainda está vazio, sugere o nome do arquivo.
      if (_titleController.text.trim().isEmpty) {
        final nome = caminhoEscolhido.split('/').last;
        final semExtensao =
            nome.contains('.') ? nome.substring(0, nome.lastIndexOf('.')) : nome;
        _titleController.text = semExtensao;
      }

      final player = AudioPlayer();
      try {
        await player.setSourceDeviceFile(caminhoEscolhido);
        Duration? duracao = await player.getDuration();

        if (duracao != null && mounted) {
          setState(() {
            _durationInSeconds = duracao.inSeconds;
          });
        }
      } catch (e) {
        debugPrint('Erro ao obter a duração: $e');
      } finally {
        await player.dispose();
      }
    }
  }

  Future<void> _novoArtista() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddArtist()),
    );
    await _loadArtists();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecione um arquivo de áudio!")),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Só copia para a pasta do app o que foi trocado nesta edição.
      String audio = _audioPath!;
      if (audio != widget.song?.audioPath) {
        audio = await FileService.persist(audio, 'songs');
      }

      String image = _imagePathController.text.trim();
      if (image != widget.song?.imagePath) {
        image = await FileService.persist(image, 'covers');
      }

      Song song = Song(
        id: widget.song?.id,
        title: _titleController.text.trim(),
        idArtist: _selectedArtistId!,
        duration: _durationInSeconds,
        audioPath: audio,
        imagePath: image,
        isFavorite: _isFavorite,
      );

      if (widget.song == null) {
        await SongDao.instance.add(song);
      } else {
        await SongDao.instance.update(song);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Song salvo com sucesso!")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
                      if (_artists.isEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text(
                              'Nenhum artista cadastrado. Cadastre um artista para continuar.',
                            ),
                            trailing: TextButton(
                              onPressed: _novoArtista,
                              child: const Text('Novo artista'),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedArtistId,
                                isExpanded: true,
                                decoration:
                                    const InputDecoration(labelText: "Artista"),
                                items: _artists.map((artist) {
                                  return DropdownMenuItem<int>(
                                    value: artist.id,
                                    child: Text(
                                      artist.artisticName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_add),
                              tooltip: 'Novo artista',
                              onPressed: _novoArtista,
                            ),
                          ],
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
                      if (_audioPath != null && _durationInSeconds == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Não foi possível ler a duração deste arquivo.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imagePathController,
                              decoration: const InputDecoration(
                                labelText: "Capa (opcional - URL ou Local)",
                              ),
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
                        onPressed: (_saving || _artists.isEmpty) ? null : _salvar,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Salvar"),
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
