import 'dart:collection';
import 'dart:convert' show utf8;

import 'package:archive/archive_io.dart' as archive;
import 'package:logging/logging.dart';
import 'package:pkgraph/src/models/package.dart';
import 'package:pkgraph/src/models/solved_dependency.dart';
import 'package:pkgraph/src/pub_api/fetch.dart';
import 'package:pkgraph/src/pub_cache/pub_cache.dart';
import 'package:pkgraph/src/retry.dart';
import 'package:http/http.dart' as http;

final _logger = Logger('Audit');

class LicenseAudit {
  final PubCache _cache;

  final Map<String, SolvedDependency> _dependencies = {};

  final Map<String, String> _licenses = {};

  final List<String> _names = [];

  final Map<String, Package> _packages = {};

  final Queue<SolvedDependency> _processQueue = Queue<SolvedDependency>();

  LicenseAudit({
    PubCache cache,
  }) : _cache = cache ?? PubCache.empty();

  Future<String> get asHtml async {
    await _drainQueue();

    String output = '';
    for (final name in _names) {
      output += '<h2>$name</h2>\n';
      final license = _licenses[name];
      output += '<pre>$license</pre>\n\n';
    }

    return output;
  }

  Future<Map<String, String>> get asJson async {
    await _drainQueue();

    return _licenses;
  }

  Future<String> get asMarkdown async {
    await _drainQueue();

    String output = '';
    for (final name in _names) {
      output += '## $name\n';
      final license = _licenses[name];
      output += '```\n$license\n```\n\n';
    }

    return output;
  }

  Future<String> get asText async {
    await _drainQueue();

    String output = '';
    for (final name in _names) {
      output += '$name\n';
      final license = _licenses[name];
      output += '$license\n\n';
    }

    return output;
  }

  Future<void> _drainQueue() async {
    while (_processQueue.isNotEmpty) {
      final dependency = _processQueue.removeFirst();
      _names.add(dependency.name);
      _dependencies[dependency.name] = dependency;

      final package = await fetchPackageVersion(
        cache: _cache,
        name: dependency.name,
        version: dependency.version,
      );
      _packages[dependency.name] = package;

      final response = await runWithRetry(
        operation: () => http.get(package.archiveUrl),
        logger: _logger,
        validate: (response) async {
          if (response.statusCode != 200) {
            throw Exception('Status code was ${response.statusCode}');
          }
        },
      );

      final tarBytes = archive.GZipDecoder().decodeBytes(response.bodyBytes);
      final tarArchive = archive.TarDecoder().decodeBytes(tarBytes);
      final licenseFile = tarArchive.findFile('LICENSE');

      if (licenseFile == null) {
        _licenses[dependency.name] = '';
      } else {
        final licenseContent = utf8.decode(licenseFile.content);
        _licenses[dependency.name] = licenseContent;
      }
    }
  }

  void add(SolvedDependency dependency) {
    _processQueue.add(dependency);
  }

  void addFromLockFile(Map lockFile) {
    if (!lockFile.containsKey('packages')) {
      throw ArgumentError('missing "packages" key');
    }

    if (lockFile['packages'] is! Map) {
      throw ArgumentError('missing packages map');
    }

    lockFile['packages'].forEach((_, jsonDependency) {
      final dependency = SolvedDependency.fromJson(jsonDependency);
      add(dependency);
    });
  }
}
