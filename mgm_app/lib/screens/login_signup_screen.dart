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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _uuid = const Uuid();

  final List<String> _sexOptions = ['F', 'M', 'Outro'];
  String? _selectedSex;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _codeController.dispose();
    _inviteController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      final email = _emailController.text.trim();

      if (await repo.isCodeTaken(myCode)) {
        _showSnack('Este código já está em uso.');
        return;
      }

      if (await repo.isEmailTaken(email)) {
        _showSnack('Este e-mail já está cadastrado.');
        return;
      }

      if (inviteCode.isNotEmpty && inviteCode == myCode) {
        _showSnack('Use o código de outra pessoa para o campo de indicação.');
        return;
      }

      final now = DateTime.now().toUtc();
      final passwordHash = hashPassword(_passwordController.text);
      final user = AppUser(
        uid: _uuid.v4(),
        name: _nameController.text.trim(),
        email: email,
        sex: _selectedSex!,
        age: int.parse(_ageController.text.trim()),
        myCode: myCode,
        pointsTotal: 0,
        invitedByCode: inviteCode.isEmpty ? null : inviteCode,
        passwordHash: passwordHash,
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

  Future<void> _loginWithAccount() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final repo = DataRepository.instance;
    AppUser? loggedUser;

    await showDialog<void>(
      context: context,
      builder: (context) {
        String? errorMessage;
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              final form = formKey.currentState;
              if (form == null || !form.validate()) {
                return;
              }
              setStateDialog(() {
                isLoading = true;
                errorMessage = null;
              });
              final user = await repo.authenticate(
                emailController.text.trim(),
                passwordController.text,
              );
              if (user == null) {
                setStateDialog(() {
                  isLoading = false;
                  errorMessage = 'Credenciais inválidas.';
                });
                return;
              }
              loggedUser = user;
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }

            return AlertDialog(
              title: const Text('Entrar na conta'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail';
                        }
                        final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!pattern.hasMatch(value.trim())) {
                          return 'Informe um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Informe a senha'
                          : null,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (loggedUser == null) {
      emailController.dispose();
      passwordController.dispose();
      return;
    }

    await repo.setCurrentUser(loggedUser!.uid);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);

    emailController.dispose();
    passwordController.dispose();
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
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _passwordVisible = !_passwordVisible;
                    }),
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (value) {
                  final base = _requiredValidator(value);
                  if (base != null) return base;
                  if (value!.length < 6) {
                    return 'Use pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirme a senha',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    }),
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !_confirmPasswordVisible,
                validator: (value) {
                  final base = _requiredValidator(value);
                  if (base != null) return base;
                  if (value != _passwordController.text) {
                    return 'As senhas não conferem';
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
                onPressed: _loginWithAccount,
                child: const Text('Já tenho cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
