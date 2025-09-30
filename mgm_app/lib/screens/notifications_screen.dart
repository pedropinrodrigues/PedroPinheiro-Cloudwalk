import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../services/data_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notificationsFuture;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<AppNotification>> _loadNotifications() async {
    final repo = DataRepository.instance;
    final user = await repo.requireCurrentUser();
    return repo.listNotificationsFor(user.uid);
  }

  Future<void> _onRefresh() async {
    final future = _loadNotifications();
    setState(() {
      _notificationsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: FutureBuilder<List<AppNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar notificações: ${snapshot.error}'),
            );
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Nenhuma notificação por enquanto.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isBonus = notification.type == 'bonus';
                final icon = isBonus
                    ? Icons.star_outline
                    : Icons.person_add_alt_1;
                final message = isBonus
                    ? 'BÔNUS desbloqueado! +${notification.pointsAwarded} pontos.'
                    : '${notification.invitedName} cadastrou-se usando seu código. +${notification.pointsAwarded} pontos.';
                final dateText = _dateFormat.format(
                  notification.createdAt.toLocal(),
                );
                return ListTile(
                  leading: Icon(icon),
                  title: Text(message),
                  subtitle: Text(dateText),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
