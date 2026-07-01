import 'dart:convert';

import '../../../core/models/json_field.dart';

class OrderRequestLine {
  OrderRequestLine({
    required this.orderRequestLineId,
    required this.sizeId,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.listPrice,
    this.lineTotal,
    this.stockQty,
  });

  final int? orderRequestLineId;
  final int sizeId;
  final String product;
  int quantity;
  final double unitPrice;
  final double listPrice;
  final double? lineTotal;
  final int? stockQty;

  double get computedTotal => quantity * unitPrice;

  factory OrderRequestLine.fromJson(Map<String, dynamic> json) {
    return OrderRequestLine(
      orderRequestLineId: json.intField('OrderRequestLineId'),
      sizeId: json.intField('SizeId') ?? 0,
      product: json.stringField('Product') ?? '',
      quantity: json.intField('Quantity') ?? 0,
      unitPrice: json.doubleField('UnitPrice') ?? 0,
      listPrice: json.doubleField('ListPrice') ?? 0,
      lineTotal: json.doubleField('LineTotal'),
      stockQty: json.intField('StockQty'),
    );
  }

  Map<String, dynamic> toPayload() => {
        'SizeId': sizeId,
        'Product': product,
        'Quantity': quantity,
        'UnitPrice': unitPrice,
        'ListPrice': listPrice,
      };

  OrderRequestLine copyWith({int? quantity}) => OrderRequestLine(
        orderRequestLineId: orderRequestLineId,
        sizeId: sizeId,
        product: product,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        listPrice: listPrice,
        lineTotal: lineTotal,
        stockQty: stockQty,
      );
}

class OrderRequestSummary {
  const OrderRequestSummary({
    required this.orderRequestId,
    required this.memberEmail,
    this.customer,
    this.note,
    required this.status,
    required this.createdAt,
    this.totalAmount,
    this.lineCount,
    this.currencyId,
  });

  final int orderRequestId;
  final String memberEmail;
  final String? customer;
  final String? note;
  final String status;
  final DateTime? createdAt;
  final double? totalAmount;
  final int? lineCount;
  final int? currencyId;

  String get displayName =>
      (customer != null && customer!.trim().isNotEmpty) ? customer!.trim() : memberEmail;

  factory OrderRequestSummary.fromJson(Map<String, dynamic> json) {
    final createdRaw = json.field('CreatedAt');
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    return OrderRequestSummary(
      orderRequestId: json.intField('OrderRequestId') ?? 0,
      memberEmail: json.stringField('MemberEmail') ?? '',
      customer: json.stringField('Customer'),
      note: json.stringField('Note'),
      status: json.stringField('Status') ?? 'Pending',
      createdAt: createdAt,
      totalAmount: json.doubleField('TotalAmount'),
      lineCount: json.intField('LineCount'),
      currencyId: json.intField('CurrencyId'),
    );
  }
}

class OrderRequestDetail {
  OrderRequestDetail({
    required this.orderRequestId,
    required this.memberEmail,
    this.customer,
    this.note,
    required this.status,
    this.createdAt,
    this.totalAmount,
    this.currencyId,
    required this.lines,
  });

  final int orderRequestId;
  final String memberEmail;
  String? customer;
  String? note;
  String status;
  final DateTime? createdAt;
  final double? totalAmount;
  final int? currencyId;
  List<OrderRequestLine> lines;

  bool get isEditable => status != 'Converted' && status != 'Rejected';

  double get computedTotal =>
      lines.fold(0, (sum, line) => sum + line.computedTotal);

  factory OrderRequestDetail.fromJson(Map<String, dynamic> json) {
    final createdRaw = json.field('CreatedAt');
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    final linesRaw = json.field('Lines');
    List<OrderRequestLine> lines = [];
    if (linesRaw is String && linesRaw.isNotEmpty) {
      final decoded = jsonDecode(linesRaw) as List<dynamic>;
      lines = decoded
          .map((e) => OrderRequestLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (linesRaw is List) {
      lines = linesRaw
          .map((e) => OrderRequestLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return OrderRequestDetail(
      orderRequestId: json.intField('OrderRequestId') ?? 0,
      memberEmail: json.stringField('MemberEmail') ?? '',
      customer: json.stringField('Customer'),
      note: json.stringField('Note'),
      status: json.stringField('Status') ?? 'Pending',
      createdAt: createdAt,
      totalAmount: json.doubleField('TotalAmount'),
      currencyId: json.intField('CurrencyId'),
      lines: lines,
    );
  }
}

String orderStatusLabel(String status) => switch (status) {
      'Pending' => 'Bekliyor',
      'Accepted' => 'Onaylandı',
      'Rejected' => 'Reddedildi',
      'Converted' => 'Tamamlandı',
      _ => status,
    };
