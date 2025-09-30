import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'local_store.dart';
import 'local_store_seed.dart';

class LocalStoreImpl implements LocalStore {
  static const _storageKey = 'mgm_app_data';

  @override
  Future<Map<String, dynamic>> readAll() async {
    final raw = html.window.localStorage[_storageKey];
    if (raw == null) {
      final seed = buildSeedData();
      await writeAll(seed);
      return seed;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      final seed = buildSeedData();
      await writeAll(seed);
      return seed;
    }
  }

  @override
  Future<void> writeAll(Map<String, dynamic> data) async {
    html.window.localStorage[_storageKey] = jsonEncode(data);
  }
}

LocalStore createLocalStore() => LocalStoreImpl();
