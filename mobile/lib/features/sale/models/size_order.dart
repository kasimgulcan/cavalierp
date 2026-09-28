/// Beden sırası `VSizeSetSize.Pos` ile gelir. Küçük beden küçük `Pos` değeridir.
///
/// `Pos` gelmeyen satırlar, sırası belli olanların ardında ve kendi aralarında
/// etikete göre durur.
int compareBySizePosition({
  required int? positionA,
  required int? positionB,
  String labelA = '',
  String labelB = '',
}) {
  if (positionA != null && positionB != null) {
    final byPosition = positionA.compareTo(positionB);
    if (byPosition != 0) return byPosition;
  } else if (positionA != null) {
    return -1;
  } else if (positionB != null) {
    return 1;
  }
  return labelA.compareTo(labelB);
}
