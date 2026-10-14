import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:Jukefy/database/user_dao.dart';
import 'package:Jukefy/model/user.dart';
import 'package:Jukefy/services/auth_service.dart';
import 'package:Jukefy/services/file_service.dart';
import 'package:Jukefy/widgets/app_image.dart';

/// Cadastro de usuário. Se [user] for informado, vira edição de perfil.
class RegisterUserPage extends StatefulWidget {
  final User? user;
  const RegisterUserPage({super.key, this.user});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _imagePath;
  bool _obscure = true;
  bool _saving = false;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _imagePath = user.imagePath;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _imagePath = result.files.single.path!);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      String? image = _imagePath;
      if (image != null &&
          image.isNotEmpty &&
          image != widget.user?.imagePath) {
        image = await FileService.persist(image, 'user_images');
      }

      if (_isEditing) {
        final current = widget.user!;
        final newEmail = _emailController.text.trim().toLowerCase();

        if (newEmail != current.email) {
          final existing = await UserDao.instance.getByEmail(newEmail);
          if (existing != null && existing.id != current.id) {
            _showMessage('Já existe uma conta com esse e-mail.');
            return;
          }
        }

        final newPassword = _passwordController.text;
        final updated = User(
          id: current.id,
          name: _nameController.text.trim(),
          email: newEmail,
          password: newPassword.isEmpty
              ? current.password
              : AuthService.hashPassword(newPassword),
          imagePath: (image == null || image.isEmpty) ? null : image,
        );

        await AuthService.instance.updateProfile(updated);
        if (!mounted) return;
        _showMessage('Perfil atualizado!');
        Navigator.pop(context);
      } else {
        final error = await AuthService.instance.register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          imagePath: image,
        );
        if (!mounted) return;

        if (error != null) {
          _showMessage(error);
          return;
        }
        // Usuário já está logado: volta à raiz (o AuthGate mostra a Homepage).
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showMessage('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar perfil' : 'Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AppImage(
                        path: _imagePath,
                        size: 110,
                        circular: true,
                        icon: Icons.person,
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Foto (opcional)',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Informe o e-mail';
                    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!valid.hasMatch(text)) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: _isEditing
                        ? 'Nova senha (deixe em branco para manter)'
                        : 'Senha',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) {
                    final text = value ?? '';
                    if (_isEditing && text.isEmpty) return null;
                    if (text.isEmpty) return 'Informe a senha';
                    if (text.length < 6) return 'Mínimo de 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar senha'),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Salvar' : 'Cadastrar'),
                  ),
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
