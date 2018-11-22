/// A model to represent the type of a particular dependency from
/// a pubspec.lock file.
class DependencyType {
  static const directDev = DependencyType._('direct dev');

  static const directMain = DependencyType._('direct main');

  static const transitive = DependencyType._('transitive');

  /// Type name for output.
  final String name;

  const DependencyType._(this.name);

  /// Whether or not this dependency is direct in one way or
  /// another.
  bool get isDirect => this == directDev || this == directMain;
}
