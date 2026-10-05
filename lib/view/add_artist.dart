import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../model/artist.dart';
import '../database/artist_dao.dart';

class AddArtist extends StatefulWidget {
  final Artist? artist;
  const AddArtist({super.key, this.artist});

  @override
  State<AddArtist> createState() => _AddArtistState();
}

class _AddArtistState extends State<AddArtist> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _artisticNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.artist != null) {
      _nameController.text = widget.artist!.name;
      _artisticNameController.text = widget.artist!.artisticName;
      _descriptionController.text = widget.artist!.description;
      _imagePathController.text = widget.artist!.imagePath;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist == null ? "Novo Artista" : "Alterando Artista"),
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
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nome"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entre com o nome do artista';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _artisticNameController,
                  decoration: const InputDecoration(labelText: "Nome Artístico"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entre com o nome artístico';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: "Descrição / Biografia"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _imagePathController,
                        decoration: const InputDecoration(
                          labelText: "Caminho da Imagem (URL ou Local)",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe ou selecione a imagem';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.image_search,
                        size: 30,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: _selecionarImagemEpegarCaminho,
                      tooltip: 'Buscar na Galeria',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Artist artist = Artist(
                        id: widget.artist?.id,
                        name: _nameController.text,
                        artisticName: _artisticNameController.text,
                        description: _descriptionController.text,
                        imagePath: _imagePathController.text,
                      );

                      if (widget.artist == null) {
                        await ArtistDao.instance.add(artist);
                      } else {
                        await ArtistDao.instance.update(artist);
                      }

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Artista salvo com sucesso!"),
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
    _nameController.dispose();
    _artisticNameController.dispose();
    _descriptionController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }
}