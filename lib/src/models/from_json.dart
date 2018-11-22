import 'package:pub_semver/pub_semver.dart';

/// Convert a string to a pubspec version during deserialization.
Version toVersion(String value) => Version.parse(value);
