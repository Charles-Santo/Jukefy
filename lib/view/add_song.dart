import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../model/song.dart';
import '../database/song_dao.dart';
import 'package:audioplayers/audioplayers.dart';

class AddSong extends StatefulWidget {
  final Song? song;
  const AddSong({super.key, this.song});

  @override
  State<AddSong> createState() => _AddSongState();
}

class _AddSongState extends State<AddSong> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();

  bool _isFavorite = false;
  String? _audioPath;
  String? _imagePath;

  @override
  void initState() {
    super.initState();

    if (widget.song != null) {
      _titleController.text = widget.song!.title;
      _artistController.text = widget.song!.artist;
      _genreController.text = widget.song!.genre;
      _durationController.text = widget.song!.duration.toString();
      
      _imagePathController.text = widget.song!.imagePath;
      _isFavorite = widget.song!.isFavorite;
      _audioPath = widget.song!.audioPath;
      _imagePath = widget.song!.imagePath;
    }
  }

  
  Future<void> _selecionarImagemEpegarCaminho() async {
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.image, 
      allowMultiple: false,
    );

    if (resultado != null && resultado.files.single.path != null) {
      setState(() {
        _imagePath = resultado.files.single.path;
        
        _imagePathController.text = _imagePath!; 
      });
      print('AQUI ESTÁ O CAMINHO DA IMAaGEM: $_imagePath');
    } else {
      print('Usuario cancelou a seleção da imagem.');
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
   
            _durationController.text = duracao.inSeconds.toString();
          });
        }
        
   
        await player.dispose(); 
      } catch (e) {
        print('Erro ao obter a duração: $e');
      }

      print('AQUI ESTÁ O CAMINHO DO ÁUDIO: $_audioPath');
    } else {
      print('Usuário cancelou a seleção do áudio.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.song == null
            ? const Text("Novo Song")
            : const Text("Alterando o Song"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entre com o título da música';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _artistController,
                  decoration: const InputDecoration(labelText: "Artista"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entre com o nome do artista';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _genreController,
                  decoration: const InputDecoration(labelText: "Gênero"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entre com o gênero musical';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: "Duração (em segundos)"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Entre com a duração';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Digite um número válido';
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
                            ? _audioPath!.split('/').last
                            : "Nenhum áudio selecionado",
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.image_search, size: 30, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                          const SnackBar(content: Text("Por favor, selecione um arquivo de áudio!")),
                        );
                        return;
                      }

                      int duration = int.tryParse(_durationController.text) ?? 0;

                      if (widget.song == null) {
                        Song novoSong = Song(
                          title: _titleController.text,
                          artist: _artistController.text,
                          genre: _genreController.text,
                          duration: duration,
                          audioPath: _audioPath!,
                          imagePath: _imagePathController.text,
                          isFavorite: _isFavorite,
                        );

                        await SongDao.instance.add(novoSong);
                      } else {
                        Song songAtualizado = Song(
                          id: widget.song!.id,
                          title: _titleController.text,
                          artist: _artistController.text,
                          genre: _genreController.text,
                          duration: duration,
                          audioPath: _audioPath!,
                          imagePath: _imagePathController.text,
                          isFavorite: _isFavorite,
                        );

                        await SongDao.instance.update(songAtualizado);
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
    _artistController.dispose();
    _genreController.dispose();
    _durationController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }
}