import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/services.dart' show rootBundle;

import 'local_store.dart';
import 'local_store_seed.dart';

class LocalStoreImpl implements LocalStore {
  static const _storageKey = 'mgm_app_data';
  bool _initialised = false;

  @override
  Future<Map<String, dynamic>> readAll() async {
    await _ensureSeeded();
    final raw = html.window.localStorage[_storageKey];
    if (raw == null) {
      return buildSeedData();
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  @override
  Future<void> writeAll(Map<String, dynamic> data) async {
    await _ensureSeeded();
    html.window.localStorage[_storageKey] = jsonEncode(data);
  }

  Future<void> _ensureSeeded() async {
    if (_initialised) return;
    final existing = html.window.localStorage[_storageKey];
    if (existing == null) {
      final seed = await _loadSeedMap();
      html.window.localStorage[_storageKey] = jsonEncode(seed);
    }
    _initialised = true;
  }

  Future<Map<String, dynamic>> _loadSeedMap() async {
    try {
      final raw = await rootBundle.loadString('assets/data.json');
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return buildSeedData();
    }
  }
}

LocalStore createLocalStore() => LocalStoreImpl();
