// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solved_dependency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SolvedDependency _$SolvedDependencyFromJson(Map<String, dynamic> json) {
  return SolvedDependency(
      type: toDependencyType(json['dependency'] as String),
      version: toVersion(json['version'] as String));
}
