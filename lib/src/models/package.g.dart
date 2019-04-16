// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Package _$PackageFromJson(Map<String, dynamic> json) {
  return Package(
      archiveUrl: json['archive_url'] == null
          ? null
          : _toUri(json['archive_url'] as String),
      pubspec: json['pubspec'] == null
          ? null
          : Pubspec.fromJson(json['pubspec'] as Map),
      version: json['version'] == null
          ? null
          : _toVersion(json['version'] as String));
}
