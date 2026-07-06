import 'package:flutter_test/flutter_test.dart';
import 'package:cavalierp/features/auth/privacy_policy_content.dart';

void main() {
  test('privacy policy has sections and no placeholder text', () {
    expect(privacyPolicySections, isNotEmpty);
    expect(privacyPolicyLastUpdated, isNotEmpty);

    final allText = privacyPolicySections
        .expand((s) => [s.title, ...s.paragraphs, ...s.bullets])
        .join('\n');

    expect(allText.toLowerCase(), isNot(contains('todo')));
    expect(allText, contains('KVKK'));
    expect(allText, contains('kullanıcı adı'));
  });
}
