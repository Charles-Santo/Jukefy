import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../model/song.dart';
import '../model/artist.dart';
import '../database/song_dao.dart';
import '../database/artist_dao.dart';
import 'add_artist.dart';

class AddSong extends StatefulWidget {
  final Song? song;
  const AddSong({super.key, this.song});

  @override
  State<AddSong> createState() => _AddSongState();
}

class _AddSongState extends State<AddSong> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imagePathController = TextEditingController();

  List<Artist> _artists = [];
  int? _selectedArtistId;
  int _durationInSeconds = 0;
  bool _isFavorite = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _loadArtists();

    final song = widget.song;
    if (song != null) {
      _titleController.text = song.title;
      _imagePathController.text = song.imagePath;
      _selectedArtistId = song.idArtist;
      _durationInSeconds = song.duration;
      _isFavorite = song.isFavorite;
      _audioPath = song.audioPath;
    }
  }

  Future<void> _loadArtists() async {
    final list = await ArtistDao.instance.getAll();
    if (!mounted) return;
    setState(() => _artists = list);
  }

  Future<void> _novoArtista() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddArtist()),
    );
    await _loadArtists();
  }

  Future<void> _selecionarImagem() async {
    final resultado = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = resultado?.files.single.path;
    if (path != null) {
      setState(() => _imagePathController.text = path);
    }
  }

  Future<void> _selecionarAudio() async {
    final resultado = await FilePicker.platform.pickFiles(type: FileType.audio);
    final path = resultado?.files.single.path;
    if (path == null) return;

    setState(() {
      _audioPath = path;
      _durationInSeconds = 0;
    });

    if (_titleController.text.trim().isEmpty) {
      final nome = path.split('/').last;
      final ponto = nome.lastIndexOf('.');
      _titleController.text = ponto > 0 ? nome.substring(0, ponto) : nome;
    }

    final player = AudioPlayer();
    try {
      await player.setSourceDeviceFile(path);
      final duracao = await player.getDuration();
      if (duracao != null && mounted) {
        setState(() => _durationInSeconds = duracao.inSeconds);
      }
    } catch (e) {
      debugPrint('Erro ao obter a duração: $e');
    } finally {
      await player.dispose();
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecione um arquivo de áudio!")),
      );
      return;
    }

    final song = Song(
      id: widget.song?.id,
      title: _titleController.text.trim(),
      idArtist: _selectedArtistId!,
      duration: _durationInSeconds,
      audioPath: _audioPath!,
      imagePath: _imagePathController.text.trim(),
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Título"),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Entre com o título da música'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedArtistId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Artista"),
                        items: _artists
                            .map((a) => DropdownMenuItem<int>(
                                  value: a.id,
                                  child: Text(a.artisticName,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedArtistId = value),
                        validator: (value) {
                          if (value != null) return null;
                          return _artists.isEmpty
                              ? 'Cadastre um artista primeiro'
                              : 'Selecione um artista';
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
                      onPressed: _selecionarAudio,
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
                          labelText: "Capa (opcional - URL ou Local)",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image_search, size: 30),
                      onPressed: _selecionarImagem,
                      tooltip: 'Buscar na Galeria',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Favoritar música?"),
                  value: _isFavorite,
                  onChanged: (value) => setState(() => _isFavorite = value),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _salvar,
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