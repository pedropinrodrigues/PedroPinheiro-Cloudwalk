import 'local_store_io.dart'
    if (dart.library.html) 'local_store_web.dart'
    as platform;

abstract class LocalStore {
  factory LocalStore() => createLocalStore();

  Future<Map<String, dynamic>> readAll();
  Future<void> writeAll(Map<String, dynamic> data);
}

LocalStore createLocalStore() => platform.createLocalStore();
