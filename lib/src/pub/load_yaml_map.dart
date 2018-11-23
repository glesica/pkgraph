import 'dart:convert' show json;

import 'package:yaml/yaml.dart';

/// Load a YAML string and convert it into a regular map.
///
// This is... awful. Since the yaml package returns weird types
// instead of just working the same way as the JSON parser,
// the easiest way to convert seems to be to just parse the
// YAML, serialize it back to JSON (which is intended to work
// properly) and then deserialize it back from JSON.
Map<String, dynamic> loadYamlMap(String yamlContent) {
  final yaml = loadYaml(yamlContent);
  final jsonContent = json.encode(yaml);
  return json.decode(jsonContent) as Map<String, dynamic>;
}
