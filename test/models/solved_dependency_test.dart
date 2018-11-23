import 'package:pkgraph/src/models/dependency_type.dart';
import 'package:test/test.dart';

import 'package:pkgraph/src/models/solved_dependency.dart';

void main() {
  group('SolvedDependency', () {
    group('.parseJson', () {
      test('should correctly parse a map', () {
        final solvedDependency = SolvedDependency.fromJson({
          'dependency': 'direct main',
          'description': {
            'name': 'nice',
            'url': 'https://pub.dartlang.org',
          },
          'source': 'hosted',
          'version': '1.0.0',
        });

        expect(solvedDependency.type, DependencyType.directMain);
        expect(solvedDependency.version.toString(), '1.0.0');
        expect(solvedDependency.description, isNotNull);
        expect(solvedDependency.name, 'nice');
        expect(solvedDependency.source, 'https://pub.dartlang.org');
      });
    });
  });
}
