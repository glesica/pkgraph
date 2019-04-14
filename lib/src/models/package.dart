import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

part 'package.g.dart';

@JsonSerializable()
class Package {
  @JsonKey(name: 'archive_url', fromJson: _toUri)
  final Uri archiveUrl;

  @JsonKey()
  final Pubspec pubspec;

  @JsonKey(fromJson: _toVersion)
  final Version version;

  Package({
    @required this.archiveUrl,
    @required this.pubspec,
    @required this.version,
  });

  factory Package.fromJson(Map json) => _$PackageFromJson(json);
}

Uri _toUri(String url) => Uri.parse(url);

Version _toVersion(String version) => Version.parse(version);
