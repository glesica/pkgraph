// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageVersion _$PackageVersionFromJson(Map<String, dynamic> json) =>
    PackageVersion(
      author: json['author'] as String? ?? '',
      authors:
          (json['authors'] as List<dynamic>?)?.map((e) => e as String) ?? [],
      dependencies:
          _toDependencies(json['dependencies'] as Map<String, dynamic>),
      description: json['description'] as String,
      devDependencies:
          _toDependencies(json['dev_dependencies'] as Map<String, dynamic>),
      homepage: Uri.parse(json['homepage'] as String),
      name: json['name'] as String,
      sdk: _toSdk(json['environment'] as Map<String, dynamic>),
      version: toVersion(json['version'] as String),
    );
