import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'local_store.dart';
import 'local_store_seed.dart';

class LocalStoreImpl implements LocalStore {
  static const _fileName = 'data.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$_fileName';
    final file = File(filePath);
    if (!await file.exists()) {
      final seed = await _loadSeedMap();
      await file.writeAsString(jsonEncode(seed), flush: true);
    }
    return file;
  }

  @override
  Future<Map<String, dynamic>> readAll() async {
    final file = await _file();
    final raw = await file.readAsString();
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  @override
  Future<void> writeAll(Map<String, dynamic> data) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(data), flush: true);
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
