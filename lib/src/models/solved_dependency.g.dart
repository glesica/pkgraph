// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solved_dependency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SolvedDependency _$SolvedDependencyFromJson(Map<String, dynamic> json) {
  return SolvedDependency(
      description: _toDescription(json['description'] as Map<String, dynamic>),
      type: _toDependencyType(json['dependency'] as String),
      version: toVersion(json['version'] as String));
}
