import 'package:pkgraph/src/models/solved_dependency.dart';
import 'package:test/test.dart';
import 'package:pkgraph/src/license/license_audit.dart';

void main() {
  group('LicenseAudit', () {
    test('should do stuff', () async {
      final audit = LicenseAudit();
      final dependency = SolvedDependency.fromJson({
        'dependency': 'direct main',
        'description': {
          'name': 'args',
          'url': 'https://pub.dartlang.org',
        },
        'source': 'hosted',
        'version': '1.5.1',
      });
      audit.add(dependency);
      final license = await audit.asJson;
      expect(license, contains('args'));
    });
  });
}
