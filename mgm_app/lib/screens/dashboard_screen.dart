import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../routes.dart';
import '../services/data_repository.dart';
import '../theme/app_colors.dart';

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

  Widget _buildPointsCard(ThemeData theme) {
    final points = _user?.pointsTotal ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seus pontos',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$points',
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+50 por cada conversão de indicação',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeCard(ThemeData theme) {
    final code = _user?.myCode ?? '-----';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu código',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: _copyCode,
              icon: const Icon(Icons.content_copy),
              label: const Text('Copiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationCard(ThemeData theme) {
    final every = _settings?['bonus_every'] ?? 0;
    final dots = _buildProgressDots();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: AppColors.bonus),
                const SizedBox(width: 8),
                Text(
                  'Gamificação',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_buildGamificationMessage(), style: theme.textTheme.bodyLarge),
            if (every > 0) ...[const SizedBox(height: 16), Row(children: dots)],
          ],
        ),
      ),
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    if (_settings == null) {
      return const SizedBox.shrink();
    }
    final bonusEvery = _settings!['bonus_every'] ?? 0;
    final bonusPoints = _settings!['bonus_points'] ?? 0;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildMetricChip(
          theme,
          icon: Icons.person_add_alt_1,
          label: 'Conversões: $_totalConversions',
          color: AppColors.primary,
        ),
        _buildMetricChip(
          theme,
          icon: Icons.star,
          label: 'Bônus: +$bonusPoints a cada $bonusEvery',
          color: AppColors.bonus,
        ),
      ],
    );
  }

  Widget _buildMetricChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  List<Widget> _buildProgressDots() {
    final every = _settings?['bonus_every'] ?? 0;
    if (every <= 0) {
      return [];
    }
    final rest = _totalConversions % every;
    final filledCount = (_totalConversions > 0 && rest == 0) ? every : rest;
    return List.generate(every, (index) {
      final isFilled = index < filledCount;
      return Container(
        width: 12,
        height: 12,
        margin: EdgeInsets.only(right: index == every - 1 ? 0 : 8),
        decoration: BoxDecoration(
          color: isFilled ? AppColors.primary : AppColors.border,
          shape: BoxShape.circle,
        ),
      );
    });
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Veja seus resultados e compartilhe seu código para continuar pontuando.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPointsCard(Theme.of(context)),
                    const SizedBox(height: 16),
                    _buildCodeCard(Theme.of(context)),
                    const SizedBox(height: 16),
                    _buildGamificationCard(Theme.of(context)),
                    const SizedBox(height: 16),
                    _buildMetrics(Theme.of(context)),
                  ],
                ],
              ),
            ),
    );
  }
}
