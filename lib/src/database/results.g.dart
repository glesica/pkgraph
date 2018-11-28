// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Results _$ResultsFromJson(Map<String, dynamic> json) {
  return Results(
      columns: (json['columns'] as List).map((e) => e as String),
      data: (json['data'] as List)
          .map((e) => Datum.fromJson(e as Map<String, dynamic>)),
      errors: (json['errors'] as List)
          .map((e) => Error.fromJson(e as Map<String, dynamic>)));
}

Datum _$DatumFromJson(Map<String, dynamic> json) {
  return Datum(
      meta: (json['meta'] as List)
          .map((e) => Meta.fromJson(e as Map<String, dynamic>)),
      row: json['row'] as List);
}

Error _$ErrorFromJson(Map<String, dynamic> json) {
  return Error(
      code: json['code'] as String, message: json['message'] as String);
}

Meta _$MetaFromJson(Map<String, dynamic> json) {
  return Meta(
      deleted: json['deleted'] as bool,
      id: json['id'] as int,
      type: json['type'] as String);
}
