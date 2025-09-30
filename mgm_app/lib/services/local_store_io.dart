import 'dart:convert';
import 'dart:io';

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
      await file.writeAsString(jsonEncode(buildSeedData()), flush: true);
    }
    return file;
  }

  @override
  Future<Map<String, dynamic>> readAll() async {
    final file = await _file();
    final raw = await file.readAsString();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> writeAll(Map<String, dynamic> data) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(data), flush: true);
  }
}

LocalStore createLocalStore() => LocalStoreImpl();
