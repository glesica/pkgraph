import 'package:pkgraph/src/models/solved_dependency.dart';
import 'package:test/test.dart';
import 'package:pkgraph/src/license/license_audit.dart';

void main() {
  group('LicenseAudit', () {
    test('should do stuff', () async {
      final audit = LicenseAudit()
        ..add(SolvedDependency.fromJson({
          'dependency': 'direct main',
          'description': {
            'name': 'args',
            'url': 'https://pub.dartlang.org',
          },
          'source': 'hosted',
          'version': '1.5.1',
        }))
        ..add(SolvedDependency.fromJson({
          'dependency': 'direct main',
          'description': {
            'name': 'fake_dep',
            'url': 'git://git.git/repo',
          },
          'source': 'git',
          'version': '1.0.0',
        }));
      final license = await audit.asJson;
      expect(license, contains('args'));
      expect(license, isNot(contains('fake_dep')));
    });
  });
}
