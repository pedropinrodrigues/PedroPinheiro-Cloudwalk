import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../routes.dart';
import '../services/data_repository.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _codeController = TextEditingController();
  final _inviteController = TextEditingController();
  final _uuid = const Uuid();

  final List<String> _sexOptions = ['F', 'M', 'Outro'];
  String? _selectedSex;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _codeController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      final repo = DataRepository.instance;
      final myCode = _codeController.text.trim();
      final inviteCode = _inviteController.text.trim();

      final codeTaken = await repo.isCodeTaken(myCode);
      if (codeTaken) {
        _showSnack('Este código já está em uso.');
        return;
      }

      if (inviteCode.isNotEmpty && inviteCode == myCode) {
        _showSnack('Use o código de outra pessoa para o campo de indicação.');
        return;
      }

      final now = DateTime.now().toUtc();
      final user = AppUser(
        uid: _uuid.v4(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        sex: _selectedSex!,
        age: int.parse(_ageController.text.trim()),
        myCode: myCode,
        pointsTotal: 0,
        invitedByCode: inviteCode.isEmpty ? null : inviteCode,
        createdAt: now,
        updatedAt: now,
      );

      await repo.upsertUser(user);

      if (inviteCode.isNotEmpty) {
        final inviter = await repo.findUserByCode(inviteCode);
        if (inviter != null) {
          await repo.awardConversionPoints(
            inviterUid: inviter.uid,
            inviterCode: inviter.myCode,
            invitedName: user.name,
          );
        }
      }

      await repo.setCurrentUser(user.uid);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } catch (error) {
      _showSnack('Erro ao salvar cadastro: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      } else {
        _isSubmitting = false;
      }
    }
  }

  Future<void> _loginWithCode() async {
    final controller = TextEditingController();
    final repo = DataRepository.instance;

    final code = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Entrar com meu código'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Seu código (5 dígitos)',
              counterText: '',
            ),
            maxLength: 5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );

    if (code == null || code.isEmpty) {
      return;
    }

    final user = await repo.findUserByCode(code);
    if (user == null) {
      if (mounted) {
        _showSnack('Nenhum usuário encontrado com este código.');
      }
      return;
    }

    await repo.setCurrentUser(user.uid);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
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
      appBar: AppBar(title: const Text('Programa Indique e Ganhe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cadastre-se para participar do Member-Get-Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
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
                      (sex) => DropdownMenuItem(value: sex, child: Text(sex)),
                    )
                    .toList(),
                decoration: const InputDecoration(labelText: 'Sexo'),
                onChanged: (value) => setState(() => _selectedSex = value),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Seu código (5 dígitos)',
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                validator: (value) {
                  final base = _requiredValidator(value);
                  if (base != null) return base;
                  final cleaned = value!.trim();
                  if (!RegExp(r'^\d{5}$').hasMatch(cleaned)) {
                    return 'Use exatamente 5 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _inviteController,
                decoration: const InputDecoration(
                  labelText: 'Código de indicação (opcional)',
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (!RegExp(r'^\d{5}$').hasMatch(value.trim())) {
                    return 'Código de indicação deve ter 5 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cadastrar'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loginWithCode,
                child: const Text('Já tenho cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
