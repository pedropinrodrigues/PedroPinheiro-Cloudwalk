import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../routes.dart';
import '../services/data_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppUser? _user;
  Map<String, int>? _settings;
  int _totalConversions = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final repo = DataRepository.instance;
      final user = await repo.requireCurrentUser();
      final settings = await repo.loadSettings();
      final conversions = await repo.countConversionsFor(user.uid);
      if (!mounted) return;
      setState(() {
        _user = user;
        _settings = settings;
        _totalConversions = conversions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  Future<void> _copyCode() async {
    final code = _user?.myCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado!')));
  }

  String _buildGamificationMessage() {
    if (_settings == null || _user == null) {
      return '';
    }
    final every = _settings!['bonus_every'] ?? 0;
    final bonus = _settings!['bonus_points'] ?? 0;
    if (every <= 0) {
      return 'Conceda indicações para ganhar recompensas.';
    }
    final rest = _totalConversions % every;
    if (_totalConversions > 0 && rest == 0) {
      return 'Você acabou de ganhar +$bonus bônus!';
    }
    final faltam = rest == 0 ? every : (every - rest);
    return 'Faltam $faltam conversões para ganhar +$bonus bônus';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.notifications);
              if (mounted) {
                await _loadData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () async {
              await Navigator.of(context).pushNamed(AppRoutes.profile);
              if (mounted) {
                await _loadData();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  if (_user != null) ...[
                    Text(
                      'Olá, ${_user!.name.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seus pontos',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_user!.pointsTotal}',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seu código',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _user!.myCode,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: _copyCode,
                              tooltip: 'Copiar código',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  'Gamificação',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _buildGamificationMessage(),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total de conversões: $_totalConversions',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
