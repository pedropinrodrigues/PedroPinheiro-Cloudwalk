import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/data_repository.dart';
import '../theme/app_colors.dart';

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
      final newEmail = _emailController.text.trim();
      if (newEmail.toLowerCase() != _user!.email.toLowerCase()) {
        final emailTaken = await repo.isEmailTaken(newEmail);
        if (emailTaken) {
          _showSnack('Este e-mail já está em uso.');
          setState(() => _saving = false);
          return;
        }
      }
      final updated = _user!.copyWith(
        name: _nameController.text.trim(),
        email: newEmail,
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Seu perfil',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Atualize seus dados básicos. Seu código permanece o mesmo.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                                hintText: 'Seu nome',
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                hintText: 'voce@exemplo.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final base = _requiredValidator(value);
                                if (base != null) return base;
                                final pattern = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!pattern.hasMatch(value!.trim())) {
                                  return 'Informe um e-mail válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSex,
                              items: _sexOptions
                                  .map(
                                    (sex) => DropdownMenuItem(
                                      value: sex,
                                      child: Text(sex),
                                    ),
                                  )
                                  .toList(),
                              decoration: const InputDecoration(
                                labelText: 'Sexo',
                                hintText: 'Selecione uma opção',
                              ),
                              onChanged: (value) =>
                                  setState(() => _selectedSex = value),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Selecione uma opção'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Idade',
                                hintText: '18',
                              ),
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
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: _user?.myCode ?? '',
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Seu código',
                                helperText:
                                    'Não é possível alterar no momento.',
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Salvar alterações'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
