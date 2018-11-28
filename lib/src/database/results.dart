import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'results.g.dart';

@JsonSerializable(nullable: false)
class Results {
  final Iterable<String> columns;

  final Iterable<Datum> data;

  final Iterable<Error> errors;

  Results({
    @required this.columns,
    @required this.data,
    @required this.errors,
  });

  factory Results.fromJson(Map<String, dynamic> json) =>
      _$ResultsFromJson(json);

  @JsonKey(ignore: true)
  bool get hasErrors => errors.isNotEmpty;
}

@JsonSerializable(nullable: false)
class Datum {
  final Iterable<Meta> meta;

  final Iterable<dynamic> row;

  Datum({
    @required this.meta,
    @required this.row,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => _$DatumFromJson(json);
}

@JsonSerializable(nullable: false)
class Error {
  final String code;

  final String message;

  Error({
    @required this.code,
    @required this.message,
  });

  factory Error.fromJson(Map<String, dynamic> json) => _$ErrorFromJson(json);
}

@JsonSerializable()
class Meta {
  final bool deleted;

  final int id;

  final String type;

  Meta({
    @required this.deleted,
    @required this.id,
    @required this.type,
  });

  factory Meta.fromJson(Map<String, dynamic> json) => _$MetaFromJson(json);
}
