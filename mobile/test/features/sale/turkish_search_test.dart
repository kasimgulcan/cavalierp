import 'package:cavalierp/features/sale/turkish_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dotted i also searches the dotless form used by uppercase ASCII I', () {
    expect(turkishISearchVariants('leggings'), ['leggings', 'leggıngs']);
  });

  test('dotless ı also searches the dotted form', () {
    expect(turkishISearchVariants('leggıngs'), ['leggıngs', 'leggings']);
  });

  test('uppercase I and İ swap with each other', () {
    expect(turkishISearchVariants('LEGGINGS'), ['LEGGINGS', 'LEGGİNGS']);
    expect(turkishISearchVariants('LEGGİNGS'), ['LEGGİNGS', 'LEGGINGS']);
  });

  test('text without Turkish I is unchanged', () {
    expect(turkishISearchVariants('top'), ['top']);
    expect(turkishISearchVariants('869123'), ['869123']);
  });

  test('each I letter is expanded independently', () {
    expect(
      turkishISearchVariants('mini'),
      ['mini', 'mıni', 'minı', 'mını'],
    );
  });

  test('long queries only use the original and the fully swapped form', () {
    expect(
      turkishISearchVariants('mississippi'),
      ['mississippi', 'mıssıssıppı'],
    );
  });
}
