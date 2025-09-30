import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/data_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();

  final List<String> _sexOptions = ['F', 'M', 'Outro'];
  String? _selectedSex;
  AppUser? _user;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final repo = DataRepository.instance;
      final user = await repo.requireCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _ageController.text = user.age.toString();
        _selectedSex = user.sex;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _user == null) {
      return;
    }

    setState(() => _saving = true);
    final repo = DataRepository.instance;
    try {
      final updated = _user!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        sex: _selectedSex,
        age: int.parse(_ageController.text.trim()),
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.upsertUser(updated);
      await repo.setCurrentUser(updated.uid);
      if (!mounted) return;
      setState(() => _user = updated);
      _showSnack('Perfil atualizado com sucesso.');
    } catch (error) {
      _showSnack('Erro ao salvar perfil: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      } else {
        _saving = false;
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_user != null)
                      Card(
                        child: ListTile(
                          title: const Text('Seu código'),
                          subtitle: Text(_user!.myCode),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        final base = _requiredValidator(value);
                        if (base != null) return base;
                        if (value!.trim().length < 2) {
                          return 'Informe pelo menos 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final base = _requiredValidator(value);
                        if (base != null) return base;
                        final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!pattern.hasMatch(value!.trim())) {
                          return 'Informe um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSex,
                      items: _sexOptions
                          .map(
                            (sex) =>
                                DropdownMenuItem(value: sex, child: Text(sex)),
                          )
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      onChanged: (value) =>
                          setState(() => _selectedSex = value),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Selecione uma opção'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Idade'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final base = _requiredValidator(value);
                        if (base != null) return base;
                        final parsed = int.tryParse(value!.trim());
                        if (parsed == null || parsed < 13) {
                          return 'Idade mínima 13 anos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
