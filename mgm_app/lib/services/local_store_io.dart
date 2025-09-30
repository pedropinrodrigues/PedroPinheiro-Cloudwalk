import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'local_store.dart';
import 'local_store_seed.dart';

class LocalStoreImpl implements LocalStore {
  static const _fileName = 'data.json';

  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) {
      return _cachedFile!;
    }

    final file = await _resolvePreferredFile();
    if (!await file.exists()) {
      final seed = await _loadSeedMap();
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(seed), flush: true);
    }
    _cachedFile = file;
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
    await _maybeMirrorToProjectFile(data);
  }

  Future<Map<String, dynamic>> _loadSeedMap() async {
    try {
      final raw = await rootBundle.loadString('assets/data.json');
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return buildSeedData();
    }
  }

  Future<File> _resolvePreferredFile() async {
    if (_shouldUseProjectFile()) {
      final projectFile = File(p.join(_projectDirPath(), 'assets', _fileName));
      return projectFile;
    }
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final filePath = p.join(directory.path, _fileName);
    return File(filePath);
  }

  bool _shouldUseProjectFile() {
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  String _projectDirPath() {
    return Directory.current.path;
  }

  Future<void> _maybeMirrorToProjectFile(Map<String, dynamic> data) async {
    if (_shouldUseProjectFile()) {
      // Already writing directly to project file.
      return;
    }

    try {
      final projectFile = File(p.join(_projectDirPath(), 'assets', _fileName));
      await projectFile.create(recursive: true);
      await projectFile.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // Ignore mirroring errors on platforms without direct filesystem access.
    }
  }
}

LocalStore createLocalStore() => LocalStoreImpl();
