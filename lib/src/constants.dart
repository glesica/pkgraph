import 'package:pub_semver/pub_semver.dart';

final dart1Versions = VersionConstraint.parse('^1.0.0');

final dart2Versions = VersionConstraint.parse('^2.0.0');

/// Default hosted package source.
const defaultSource = 'https://pub.dartlang.org';

/// Packages endpoint for a pub server.
const packageEndpoint = '/api/packages/';
