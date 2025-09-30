import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:mgm_app/services/hive_store.dart';

void main() {
  late Directory tempDir;
  late HiveStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mgm_hive_test');
    Hive.init(tempDir.path);
    store = HiveStore();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('mgm_data_box')) {
      await Hive.box<dynamic>('mgm_data_box').close();
    }
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('ensureInitialized seeds data and persists writes', () async {
    await store.ensureInitialized();

    final data = await store.readAll();
    expect(data['users'], isNotEmpty);
    expect(data['notifications'], isNotEmpty);

    data['session'] = {'current_uid': 'test-user'};
    await store.writeAll(data);

    final persisted = await store.readAll();
    expect(persisted['session']['current_uid'], 'test-user');
  });

  test('exportAsJson returns formatted json string', () async {
    await store.ensureInitialized();
    final json = await store.exportToJson();
    expect(json, contains('"users"'));
    expect(json.trim().startsWith('{'), isTrue);
  });
}
