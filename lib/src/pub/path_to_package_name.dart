import 'package:path/path.dart' as path;

/// Convert a properly formatted path to a package to just a
/// simple package name.
String pathToPackageName(String packagePath) => path.basename(packagePath);
