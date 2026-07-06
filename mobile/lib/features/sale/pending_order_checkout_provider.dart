import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingOrderCheckout {
  const PendingOrderCheckout({
    required this.orderRequestId,
    this.customer,
    this.phone,
    this.email,
    this.note,
  });

  final int orderRequestId;
  final String? customer;
  final String? phone;
  final String? email;
  final String? note;
}

final pendingOrderCheckoutProvider =
    StateProvider<PendingOrderCheckout?>((ref) => null);
