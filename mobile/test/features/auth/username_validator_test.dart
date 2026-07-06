import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/auth/username_validator.dart';

void main() {
  group('validateUsername', () {
    test('accepts valid username', () {
      expect(validateUsername('demo_user'), isNull);
      expect(validateUsername('User123'), isNull);
    });

    test('accepts 2-character username', () {
      expect(validateUsername('ab'), isNull);
    });

    test('rejects empty and single-character usernames', () {
      expect(validateUsername(''), isNotNull);
      expect(validateUsername('a'), isNotNull);
    });

    test('rejects invalid characters', () {
      expect(validateUsername('user@name'), isNotNull);
      expect(validateUsername('user name'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('accepts 2-character password', () {
      expect(validatePassword('ab'), isNull);
    });

    test('rejects empty and single-character password', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword('a'), isNotNull);
    });
  });

  group('validatePasswordConfirmation', () {
    test('accepts matching confirmation', () {
      expect(validatePasswordConfirmation('secret', 'secret'), isNull);
    });

    test('rejects empty or mismatched confirmation', () {
      expect(validatePasswordConfirmation('', 'secret'), isNotNull);
      expect(validatePasswordConfirmation('other', 'secret'), isNotNull);
    });
  });
}
