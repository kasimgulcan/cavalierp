import 'package:flutter_test/flutter_test.dart';
import 'package:csm_stok_mobile/core/models/exec_sp_response.dart';

void main() {
  test('ExecSpResponse fromJson success', () {
    final r = ExecSpResponse.fromJson({
      'success': true,
      'data': [],
      'error': null,
    });
    expect(r.success, isTrue);
    expect(r.data, isEmpty);
  });
}
