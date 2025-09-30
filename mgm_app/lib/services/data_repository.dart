import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../models/app_notification.dart';
import '../models/user.dart';
import 'local_store.dart';

class DataRepository {
  DataRepository._internal();

  static final DataRepository instance = DataRepository._internal();

  final LocalStore _store = LocalStore();
  final Uuid _uuid = const Uuid();

  Future<void> ensureInitialized() async {
    await _store.readAll();
  }

  Future<Map<String, dynamic>> _read() => _store.readAll();

  Future<void> _write(Map<String, dynamic> data) => _store.writeAll(data);

  Future<AppUser?> getCurrentUser() async {
    final data = await _read();
    final session = Map<String, dynamic>.from(data['session'] as Map);
    final uid = session['current_uid'] as String?;
    if (uid == null) {
      return null;
    }
    return findUserByUid(uid);
  }

  Future<AppUser> requireCurrentUser() async {
    final user = await getCurrentUser();
    if (user == null) {
      throw StateError('No user in session');
    }
    return user;
  }

  Future<void> setCurrentUser(String? uid) async {
    final data = await _read();
    final session = Map<String, dynamic>.from(data['session'] as Map);
    session['current_uid'] = uid;
    data['session'] = session;
    await _write(data);
  }

  Future<bool> isCodeTaken(String code) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
    return users.any((user) => user['my_code'] == code);
  }

  Future<bool> isEmailTaken(String email) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
    return users.any(
      (user) => (user['email'] as String).toLowerCase() == email.toLowerCase(),
    );
  }

  Future<AppUser?> findUserByCode(String code) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
    for (final user in users) {
      if (user['my_code'] == code) {
        return AppUser.fromJson(user);
      }
    }
    return null;
  }

  Future<AppUser?> findUserByUid(String uid) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
    for (final user in users) {
      if (user['uid'] == uid) {
        return AppUser.fromJson(user);
      }
    }
    return null;
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((user) => Map<String, dynamic>.from(user as Map))
        .toList();
    for (final user in users) {
      if ((user['email'] as String).toLowerCase() == email.toLowerCase()) {
        return AppUser.fromJson(user);
      }
    }
    return null;
  }

  Future<AppUser> upsertUser(AppUser user) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final index = users.indexWhere((element) => element['uid'] == user.uid);
    final json = user.toJson();
    if (index >= 0) {
      users[index] = json;
    } else {
      users.add(json);
    }
    data['users'] = users;
    await _write(data);
    return user;
  }

  Future<AppUser?> authenticate(String email, String password) async {
    final user = await findUserByEmail(email);
    if (user == null) {
      return null;
    }
    final hash = hashPassword(password);
    if (hash != user.passwordHash) {
      return null;
    }
    return user;
  }

  Future<void> awardConversionPoints({
    required String inviterUid,
    required String inviterCode,
    required String invitedName,
  }) async {
    final data = await _read();
    final users = (data['users'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final userIndex = users.indexWhere(
      (element) => element['uid'] == inviterUid,
    );
    if (userIndex < 0) {
      return;
    }
    final now = DateTime.now().toUtc();
    final notifications = (data['notifications'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final currentPoints = (users[userIndex]['points_total'] as num).toInt();
    users[userIndex]['points_total'] = currentPoints + 50;
    users[userIndex]['updated_at'] = now.toIso8601String();

    notifications.add({
      'id': _uuid.v4(),
      'inviter_uid': inviterUid,
      'inviter_code': inviterCode,
      'invited_name': invitedName,
      'points_awarded': 50,
      'type': 'conversion',
      'created_at': now.toIso8601String(),
    });

    final settings = Map<String, dynamic>.from(data['settings'] as Map);
    final every = (settings['bonus_every'] as num).toInt();
    final totalConversions = notifications
        .where(
          (notification) =>
              notification['inviter_uid'] == inviterUid &&
              notification['type'] == 'conversion',
        )
        .length;

    if (every > 0 && totalConversions % every == 0) {
      final bonusPoints = (settings['bonus_points'] as num).toInt();
      final bonusTime = DateTime.now().toUtc();
      final updatedPoints =
          (users[userIndex]['points_total'] as num).toInt() + bonusPoints;
      users[userIndex]['points_total'] = updatedPoints;
      users[userIndex]['updated_at'] = bonusTime.toIso8601String();
      notifications.add({
        'id': _uuid.v4(),
        'inviter_uid': inviterUid,
        'inviter_code': inviterCode,
        'invited_name': '',
        'points_awarded': bonusPoints,
        'type': 'bonus',
        'created_at': bonusTime.toIso8601String(),
      });
    }

    data['users'] = users;
    data['notifications'] = notifications;
    await _write(data);
  }

  Future<List<AppNotification>> listNotificationsFor(String inviterUid) async {
    final data = await _read();
    final notifications = (data['notifications'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final filtered =
        notifications
            .where((notification) => notification['inviter_uid'] == inviterUid)
            .map(
              (notification) => AppNotification.fromJson(
                Map<String, dynamic>.from(notification),
              ),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<int> countConversionsFor(String inviterUid) async {
    final data = await _read();
    final notifications = (data['notifications'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return notifications
        .where(
          (notification) =>
              notification['inviter_uid'] == inviterUid &&
              notification['type'] == 'conversion',
        )
        .length;
  }

  Future<Map<String, int>> loadSettings() async {
    final data = await _read();
    final settings = Map<String, dynamic>.from(data['settings'] as Map);
    return {
      'bonus_every': (settings['bonus_every'] as num).toInt(),
      'bonus_points': (settings['bonus_points'] as num).toInt(),
    };
  }
}

String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
