/// API yanıtları PascalCase veya camelCase olabilir.
extension JsonFieldAccess on Map<String, dynamic> {
  dynamic field(String pascalName) {
    final value = this[pascalName];
    if (value != null) return value;
    final camel = pascalName[0].toLowerCase() + pascalName.substring(1);
    return this[camel];
  }

  int? intField(String name) {
    final value = field(name);
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? stringField(String name) {
    final value = field(name);
    return value?.toString();
  }

  double? doubleField(String name) {
    final value = field(name);
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

List<Map<String, dynamic>> parseRowList(dynamic data) {
  if (data is List) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
}

/// Auth.Login / Auth.Register JWT yanıtı (accessToken + refreshToken içeren map).
Map<String, dynamic>? parseAuthPayload(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

String? readAuthToken(Map<String, dynamic> data, String key) {
  final value = data[key] ?? data[key[0].toUpperCase() + key.substring(1)];
  return value is String ? value : null;
}
