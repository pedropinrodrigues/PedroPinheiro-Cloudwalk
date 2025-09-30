import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final args = _parseArgs(arguments);
  final hiveDir = args['hive-dir'];
  final port = int.tryParse(args['port'] ?? '') ?? 8080;
  final bindAddress = args['bind'] ?? InternetAddress.loopbackIPv4.address;

  final targetDirPath = hiveDir ?? Directory.current.path;
  final sourceDir = Directory(targetDirPath);
  if (!sourceDir.existsSync()) {
    stderr.writeln('Hive directory "$targetDirPath" not found.');
    exit(1);
  }

  final server = await HttpServer.bind(bindAddress, port);
  stdout.writeln('Export server listening on http://$bindAddress:$port/export');
  stdout.writeln('Press CTRL+C to stop.');

  await for (final request in server) {
    final path = request.uri.path;
    if (path == '/export' || path == 'export') {
      try {
        final jsonDump = await _exportSnapshot(sourceDir);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          )
          ..headers.set(
            'Content-Disposition',
            'attachment; filename="data.json"',
          )
          ..write(jsonDump);
      } catch (error, stackTrace) {
        stderr.writeln('Export error: $error\n$stackTrace');
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Failed to export data: $error');
      }
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Use /export to download the JSON dump.');
    }

    await request.response.close();
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    if (arg.startsWith('--')) {
      final split = arg.substring(2).split('=');
      if (split.length == 2) {
        result[split[0]] = split[1];
      }
    }
  }
  return result;
}

Future<String> _exportSnapshot(Directory sourceDir) async {
  final tempDir = await Directory.systemTemp.createTemp('mgm_hive_export');
  try {
    final files = sourceDir.listSync().whereType<File>().where(
      (file) => p.basename(file.path).startsWith('mgm_data_box'),
    );

    if (files.isEmpty) {
      throw StateError(
        'Nenhum arquivo mgm_data_box.* encontrado em ${sourceDir.path}',
      );
    }

    for (final file in files) {
      final targetPath = p.join(tempDir.path, p.basename(file.path));
      await file.copy(targetPath);
    }

    Hive.init(tempDir.path);
    final box = await Hive.openBox<dynamic>('mgm_data_box');
    final raw = box.get('root') ?? {};
    final snapshot = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    await box.close();
    await Hive.close();

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(snapshot);
  } finally {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Ignore cleanup errors.
    }
  }
}
