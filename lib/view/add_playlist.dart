import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:Jukefy/database/playlist_dao.dart';
import 'package:Jukefy/model/playlist.dart';
import 'package:Jukefy/services/auth_service.dart';
import 'package:Jukefy/services/file_service.dart';

class AddPlaylist extends StatefulWidget {
  final Playlist? playlist;
  const AddPlaylist({super.key, this.playlist});

  @override
  State<AddPlaylist> createState() => _AddPlaylistState();
}

class _AddPlaylistState extends State<AddPlaylist> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final playlist = widget.playlist;
    if (playlist != null) {
      _titleController.text = playlist.title;
      _descriptionController.text = playlist.description ?? '';
      _imagePathController.text = playlist.imagePath ?? '';
    }
  }

  Future<void> _selecionarImagem() async {
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final user = AuthService.instance.user;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      String imagePath = _imagePathController.text.trim();
      if (imagePath != (widget.playlist?.imagePath ?? '')) {
        imagePath = await FileService.persist(imagePath, 'playlist_images');
      }

      final description = _descriptionController.text.trim();

      final playlist = Playlist(
        id: widget.playlist?.id,
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        imagePath: imagePath.isEmpty ? null : imagePath,
        idUser: widget.playlist?.idUser ?? user.id!,
      );

      if (widget.playlist == null) {
        await PlaylistDao.instance.add(playlist);
      } else {
        await PlaylistDao.instance.update(playlist);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Playlist salva com sucesso!")),
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
        title: Text(
          widget.playlist == null ? "Nova Playlist" : "Alterando Playlist",
        ),
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entre com o título da playlist';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Descrição"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imagePathController,
                        decoration: const InputDecoration(
                          labelText: "Imagem (opcional - URL ou Local)",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.image_search,
                        size: 30,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _selecionarImagem,
                      tooltip: 'Buscar na Galeria',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _salvar,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
    _descriptionController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }
}
