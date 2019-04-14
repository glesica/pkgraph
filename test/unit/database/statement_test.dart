import 'package:test/test.dart';

import 'package:pkgraph/src/database/statement.dart';

void main() {
  group('Statement', () {
    Statement statement;

    setUp(() {
      statement = Statement(statement: 'A');
    });

    group('[] operator', () {
      test('should get a parameter key', () {
        statement.parameters['A'] = 'B';
        expect(statement['A'], 'B');
      });
    });

    group('[]= operator', () {
      test('should set a parameter key', () {
        statement['A'] = 'B';
        expect(statement.parameters, contains('A'));
        expect(statement.parameters['A'], 'B');
      });
    });

    group('set', () {
      test('should set a parameter key', () {
        statement.set('A', 'B');
        expect(statement.parameters, contains('A'));
        expect(statement.parameters['A'], 'B');
      });
    });

    group('toJson', () {
      test('should set statement key', () {
        final json = statement.toJson();
        expect(json, contains('statement'));
        expect(json['statement'], 'A');
      });

      test('should set parameters key', () {
        statement.parameters['B'] = 'C';
        final json = statement.toJson();
        expect(json, contains('parameters'));
        expect(json['parameters'], {'B': 'C'});
      });
    });
  });
}
