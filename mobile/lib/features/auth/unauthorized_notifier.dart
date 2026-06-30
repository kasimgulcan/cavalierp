import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 401 yanıtında oturumu kapatmak için dio ↔ auth arasında köprü.
class UnauthorizedNotifier {
  void Function()? onUnauthorized;

  void notify() => onUnauthorized?.call();
}

final unauthorizedNotifierProvider =
    Provider<UnauthorizedNotifier>((ref) => UnauthorizedNotifier());
