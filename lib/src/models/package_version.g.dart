// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageVersion _$PackageVersionFromJson(Map<String, dynamic> json) {
  return PackageVersion(
      author: json['author'] as String,
      authors: (json['authors'] as List).map((e) => e as String),
      dependencies:
          _toDependencies(json['dependencies'] as Map<String, dynamic>),
      description: json['description'] as String,
      homepage: Uri.parse(json['homepage'] as String),
      name: json['name'] as String,
      sdk: _toSdk(json['environment'] as Map<String, dynamic>),
      version: _toVersion(json['version'] as String));
}
