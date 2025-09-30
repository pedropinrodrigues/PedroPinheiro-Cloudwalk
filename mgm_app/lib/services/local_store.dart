import 'local_store_io.dart' if (dart.library.html) 'local_store_web.dart';

import 'local_store_seed.dart';

abstract class LocalStore {
  factory LocalStore() => createLocalStore();

  Future<Map<String, dynamic>> readAll();
  Future<void> writeAll(Map<String, dynamic> data);
}

Map<String, dynamic> seedData() => buildSeedData();
