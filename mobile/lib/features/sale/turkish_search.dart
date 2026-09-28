/// Türkçe aramada `i`, `ı`, `I` ve `İ` harflerini birbirinin yerine aranabilir kılar.
///
/// Veritabanı büyük/küçük harfi Türkçe kuralla eşitler: `i` ile `İ`, `ı` ile `I`
/// eşleşir. `LEGGINGS` bu yüzden `leggıngs` ile bulunur, `leggings` ile bulunmaz.
/// Her I ailesi harf için hem noktalı hem noktasız sorgu üretilir.
///
/// Çok sayıda I harfi olan aramalarda yalnızca yazılan metin ve tüm harfleri
/// tersine çevrilmiş hali kullanılır; böylece tek arama onlarca isteğe bölünmez.
const kTurkishISearchExpansionLimit = 3;

const _turkishILetters = {'i', 'ı', 'I', 'İ'};

List<String> turkishISearchVariants(String query) {
  if (query.isEmpty) return const [];

  final chars = query.split('');
  final positions = <int>[
    for (var i = 0; i < chars.length; i++)
      if (_turkishILetters.contains(chars[i])) i,
  ];
  if (positions.isEmpty) return [query];

  String variantForMask(int mask) {
    final next = List<String>.from(chars);
    for (var bit = 0; bit < positions.length; bit++) {
      if ((mask & (1 << bit)) == 0) continue;
      final index = positions[bit];
      next[index] = _swapTurkishI(next[index]);
    }
    return next.join();
  }

  if (positions.length > kTurkishISearchExpansionLimit) {
    final allSwapped = (1 << positions.length) - 1;
    return [variantForMask(0), variantForMask(allSwapped)];
  }

  final count = 1 << positions.length;
  return [for (var mask = 0; mask < count; mask++) variantForMask(mask)];
}

String _swapTurkishI(String char) {
  switch (char) {
    case 'i':
      return 'ı';
    case 'ı':
      return 'i';
    case 'I':
      return 'İ';
    case 'İ':
      return 'I';
    default:
      return char;
  }
}
