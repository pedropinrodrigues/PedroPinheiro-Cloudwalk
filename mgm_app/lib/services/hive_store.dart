import 'dart:convert';

import 'package:hive/hive.dart';

import 'local_store_seed.dart';

class HiveStore {
  static const _boxName = 'mgm_data_box';
  static const _dataKey = 'root';

  Future<void> ensureInitialized() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<dynamic>(_boxName);
    }
    final box = Hive.box<dynamic>(_boxName);
    if (!box.containsKey(_dataKey)) {
      await box.put(_dataKey, _deepCopy(buildSeedData()));
    }
  }

  Future<Map<String, dynamic>> readAll() async {
    await ensureInitialized();
    final box = Hive.box<dynamic>(_boxName);
    final raw = box.get(_dataKey) ?? {};
    return Map<String, dynamic>.from(_deepCopy(raw) as Map);
  }

  Future<void> writeAll(Map<String, dynamic> data) async {
    await ensureInitialized();
    final box = Hive.box<dynamic>(_boxName);
    await box.put(_dataKey, _deepCopy(data));
  }

  Future<String> exportToJson({bool pretty = true}) async {
    final data = await readAll();
    final encoder = pretty
        ? const JsonEncoder.withIndent('  ')
        : const JsonEncoder();
    return encoder.convert(data);
  }

  dynamic _deepCopy(dynamic value) {
    final encoded = jsonEncode(value);
    return jsonDecode(encoded);
  }
}
