import 'package:pkgraph/src/models/package_version.dart';
import 'package:test/test.dart';

void main() {
  group('PackageVersion', () {
    late Map<String, dynamic> json;

    setUp(() {
      json = {
        'author': 'krieger',
        'authors': ['archer', 'lana'],
        'dependencies': {
          'package_a': '^1.0.0',
          'package_b': '2.0.0',
        },
        'description': 'the description',
        'dev_dependencies': {
          'package_c': '0.1.2',
          'package_d': '^3.0.0',
        },
        'environment': {
          'sdk': '>=2.0.0 <3.0.0',
        },
        'homepage': 'https://homepage.com',
        'name': 'package',
        'version': '0.1.2',
      };
    });

    group('.fromJson', () {
      test('should correctly read a minimal map', () {
        final version = PackageVersion.fromJson(
          json,
          source: 'source',
          ordinal: 0,
        );

        expect(version.author, 'krieger');
        expect(version.authors, const ['archer', 'lana']);
        expect(version.dependencies, hasLength(2));

        final first = version.dependencies.first;
        expect(first.packageName, 'package_a');
        expect(first.constraint.toString(), '^1.0.0');
        final second = version.dependencies.last;
        expect(second.packageName, 'package_b');
        expect(second.constraint.toString(), '2.0.0');

        expect(version.description, 'the description');

        final firstDev = version.devDependencies.first;
        expect(firstDev.packageName, 'package_c');
        expect(firstDev.constraint.toString(), '0.1.2');
        final secondDev = version.devDependencies.last;
        expect(secondDev.packageName, 'package_d');
        expect(secondDev.constraint.toString(), '^3.0.0');

        expect(version.sdk.toString(), '>=2.0.0 <3.0.0');
        expect(version.homepage.toString(), 'https://homepage.com');
        expect(version.name, 'package');
        expect(version.version.toString(), '0.1.2');
        expect(version.major, 0);
        expect(version.minor, 1);
        expect(version.patch, 2);

        expect(version.source, 'source');
        expect(version.ordinal, 0);
      });
    });
  });
}
