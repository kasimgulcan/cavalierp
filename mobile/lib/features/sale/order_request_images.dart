import '../../core/models/json_field.dart';
import '../../core/network/sp_client.dart';
import 'models/order_request.dart';

Future<Map<String, String>> loadProductImageMap(SpClient client) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    final response = await client.exec('Product.Images', {}, auth: false);
    if (response.success) {
      final map = <String, String>{};
      for (final row in parseRowList(response.data)) {
        final code = row.stringField('ProductCode')?.trim();
        final url = row.stringField('ImageUrl')?.trim();
        if (code == null || code.isEmpty || url == null || url.isEmpty) {
          continue;
        }
        map.putIfAbsent(code.toUpperCase(), () => url);
      }
      if (map.isNotEmpty) return map;
    }
    if (attempt < 2) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  return {};
}

String? resolveProductImageUrl(Map<String, String> imageByCode, String? productCode) {
  final key = productCode?.trim().toUpperCase();
  if (key == null || key.isEmpty) return null;
  return imageByCode[key];
}

Future<List<OrderRequestLine>> enrichOrderRequestLinesWithImages(
  SpClient client,
  List<OrderRequestLine> lines,
) async {
  if (lines.isEmpty) {
    return lines;
  }
  if (lines.every((line) => line.imageUrl?.trim().isNotEmpty == true)) {
    return lines;
  }
  if (lines.every((line) => line.productCode?.trim().isEmpty != false)) {
    return lines;
  }

  final imageByCode = await loadProductImageMap(client);
  if (imageByCode.isEmpty) return lines;

  return [
    for (final line in lines)
      if (line.imageUrl?.trim().isNotEmpty == true)
        line
      else
        line.copyWith(
          imageUrl: resolveProductImageUrl(imageByCode, line.productCode),
        ),
  ];
}
