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
  final PubCache? _cache;

  // IMPORTANT: Note that the four fields below, _dependencies,
  // _licenses, and _names, and _packages must always have the same
  // set of keys and must never be mutated in a way that will violate
  // this invariant! When converting to null safety, the easiest
  // route was to use assertions and they will hold only if the above
  // invariant is never violated!

  final Map<String, SolvedDependency> _dependencies = {};

  final Map<String, String> _licenses = {};

  final List<String> _names = [];

  final Map<String, Package> _packages = {};

  final Queue<SolvedDependency> _processQueue = Queue<SolvedDependency>();

  final Set<String> _sources;

  LicenseAudit({
    PubCache? cache,
    Iterable<String>? sources,
  })  : _cache = cache,
        _sources = sources?.toSet() ?? Set<String>();

  Future<String> get asHtml async {
    await _drainQueue();

    String output = '';
    for (final name in _names) {
      final dependency = _dependencies[name]!;
      output += '<h2>$name ${dependency.version}</h2>\n';
      final license = _licenses[name];
      output += '<pre>$license</pre>\n\n';
    }

    return output;
  }

  Future<Map<String, Map<String, String>>> get asJson async {
    await _drainQueue();

    final jsonAudit = <String, Map<String, String>>{};
    _licenses.forEach((packageName, licenseText) {
      final dependency = _dependencies[packageName]!;
      jsonAudit[packageName] = {
        'license': licenseText,
        'version': dependency.version.toString(),
      };
    });

    return jsonAudit;
  }

  Future<String> get asMarkdown async {
    await _drainQueue();

    String output = '';
    for (final name in _names) {
      final dependency = _dependencies[name]!;
      output += '## $name ${dependency.version}\n';
      final license = _licenses[name]!;
      output += '```\n${license.trimRight()}\n```\n\n';
    }

    return output;
  }

  Future<String> get asText async {
    await _drainQueue();

    String output = '';
    for (final name in _names) {
      final dependency = _dependencies[name]!;
      output += '$name ${dependency.version}\n';
      final license = _licenses[name];
      output += '$license\n\n';
    }

    return output;
  }

  Future<void> _drainQueue() async {
    while (_processQueue.isNotEmpty) {
      final dependency = _processQueue.removeFirst();

      if (!_sources.contains(dependency.source)) {
        _logger.info(
            'skipping package ${dependency.name} (from ${dependency.source})');
        continue;
      }

      final package = await fetchPackageVersion(
        cache: _cache,
        name: dependency.name,
        version: dependency.version,
        source: dependency.sourceUri,
      );

      if (package == null) {
        _logger.info('skipping package ${dependency.name} (failed to fetch)');
        continue;
      }

      _names.add(dependency.name);
      _dependencies[dependency.name] = dependency;
      _packages[dependency.name] = package;

      final response = await runWithRetry<http.Response>(
        operation: () => http.get(package.archiveUrl),
        logger: _logger,
        validate: (response) async {
          if (response.statusCode != 200) {
            throw Exception('Status code was ${response.statusCode}');
          }
        },
      );

      if (response == null) {
        continue;
      }

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
      throw ArgumentError('wrong "packages" type');
    }

    lockFile['packages'].forEach((packageName, jsonDependency) {
      final dependency = SolvedDependency.fromJson(jsonDependency);
      add(dependency);
    });
  }
}
