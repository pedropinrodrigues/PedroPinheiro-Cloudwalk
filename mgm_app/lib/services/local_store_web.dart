import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'local_store.dart';
import 'local_store_seed.dart';

class LocalStoreImpl implements LocalStore {
  Map<String, dynamic>? _cache;

  @override
  Future<Map<String, dynamic>> readAll() async {
    if (_cache != null) {
      return _clone(_cache!);
    }
    final seed = await _loadSeedMap();
    _cache = seed;
    return _clone(seed);
  }

  @override
  Future<void> writeAll(Map<String, dynamic> data) async {
    _cache = _clone(data);
  }

  Future<Map<String, dynamic>> _loadSeedMap() async {
    try {
      final raw = await rootBundle.loadString('assets/data.json');
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return buildSeedData();
    }
  }

  Map<String, dynamic> _clone(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);
  }
}

LocalStore createLocalStore() => LocalStoreImpl();
