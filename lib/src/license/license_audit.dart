import 'dart:collection';

import 'package:archive/archive_io.dart' as archive;
import 'package:logging/logging.dart';
import 'package:pkgraph/src/models/solved_dependency.dart';
import 'package:pkgraph/src/pub_api/fetch.dart';
import 'package:pkgraph/src/pub_cache/pub_cache.dart';
import 'package:pkgraph/src/retry.dart';
import 'package:http/http.dart' as http;

final _logger = Logger('Audit');

class LicenseAudit {
  final PubCache _cache;

  final Queue<SolvedDependency> _dependencies = Queue<SolvedDependency>();

  String _license;

  LicenseAudit({
    PubCache cache,
  }) : _cache = cache ?? PubCache.empty();

  String get asHtml => '';

  Map<String, dynamic> get asJson => {};

  String get asMarkdown => '';

  Future<String> get asText async {
    await _processQueue();
    return _license;
  }

  Future<void> _processQueue() async {
    while (_dependencies.isNotEmpty) {
      final dependency = _dependencies.removeFirst();

      // grab package data
      final package = await fetchPackageVersion(
        name: dependency.name,
        version: dependency.version,
      );
      // download tar.gz file
      final response = await runWithRetry(
        operation: () => http.get(package.archiveUrl),
        logger: _logger,
        validate: (response) async {
          if (response.statusCode != 200) {
            throw Exception('Status code was ${response.statusCode}');
          }
        },
      );
      // extract the file
      final tarBytes = archive.GZipDecoder().decodeBytes(response.bodyBytes);
      final tarArchive = archive.TarDecoder().decodeBytes(tarBytes);

      // look for a license file
      final licenseFile = tarArchive.findFile('LICENSE');
      _license = licenseFile.toString();

      // if missing, mark the license as unknown and bail
      // if it exists, load it
      // record the full license text
      // compare against known licenses
      // if it matches, mark the license type and bail
      // flag the license for followup
    }
  }

  void add(SolvedDependency dependency) {
    _dependencies.add(dependency);
  }
}
