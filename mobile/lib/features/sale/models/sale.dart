import 'dart:convert';

import '../../../core/models/json_field.dart';

class SaleLine {
  SaleLine({
    required this.saleLineId,
    required this.sizeId,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.listPrice,
    this.lineTotal,
    this.stockQty,
  });

  final int? saleLineId;
  final int sizeId;
  final String product;
  int quantity;
  final double unitPrice;
  final double listPrice;
  final double? lineTotal;
  final int? stockQty;

  double get computedTotal => quantity * unitPrice;

  factory SaleLine.fromJson(Map<String, dynamic> json) {
    return SaleLine(
      saleLineId: json.intField('SaleLineId'),
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

  SaleLine copyWith({int? quantity}) => SaleLine(
        saleLineId: saleLineId,
        sizeId: sizeId,
        product: product,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice,
        listPrice: listPrice,
        lineTotal: lineTotal,
        stockQty: stockQty,
      );
}

class SaleSummary {
  const SaleSummary({
    required this.saleId,
    required this.staffEmail,
    this.customer,
    this.note,
    this.paymentTypeId,
    this.orderRequestId,
    required this.createdAt,
    this.subtotalAmount,
    this.totalAmount,
    this.discountPercent,
    this.discountFixedAmount,
    this.lineCount,
    this.currencyId,
  });

  final int saleId;
  final String staffEmail;
  final String? customer;
  final String? note;
  final int? paymentTypeId;
  final int? orderRequestId;
  final DateTime? createdAt;
  final double? subtotalAmount;
  final double? totalAmount;
  final double? discountPercent;
  final double? discountFixedAmount;
  final int? lineCount;
  final int? currencyId;

  String get displayName =>
      (customer != null && customer!.trim().isNotEmpty) ? customer!.trim() : staffEmail;

  factory SaleSummary.fromJson(Map<String, dynamic> json) {
    final createdRaw = json.field('CreatedAt');
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    return SaleSummary(
      saleId: json.intField('SaleId') ?? 0,
      staffEmail: json.stringField('StaffEmail') ?? '',
      customer: json.stringField('Customer'),
      note: json.stringField('Note'),
      paymentTypeId: json.intField('PaymentTypeId'),
      orderRequestId: json.intField('OrderRequestId'),
      createdAt: createdAt,
      subtotalAmount: json.doubleField('SubtotalAmount'),
      totalAmount: json.doubleField('TotalAmount'),
      discountPercent: json.doubleField('DiscountPercent'),
      discountFixedAmount: json.doubleField('DiscountFixedAmount'),
      lineCount: json.intField('LineCount'),
      currencyId: json.intField('CurrencyId'),
    );
  }
}

class SaleDetail {
  SaleDetail({
    required this.saleId,
    required this.staffEmail,
    this.customer,
    this.note,
    this.paymentTypeId,
    this.orderRequestId,
    this.createdAt,
    this.subtotalAmount,
    this.totalAmount,
    this.discountPercent,
    this.discountFixedAmount,
    this.currencyId,
    required this.lines,
  });

  final int saleId;
  final String staffEmail;
  String? customer;
  String? note;
  int? paymentTypeId;
  final int? orderRequestId;
  final DateTime? createdAt;
  final double? subtotalAmount;
  final double? totalAmount;
  final double? discountPercent;
  final double? discountFixedAmount;
  final int? currencyId;
  List<SaleLine> lines;

  double get computedTotal => lines.fold(0, (sum, line) => sum + line.computedTotal);

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    final createdRaw = json.field('CreatedAt');
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    final linesRaw = json.field('Lines');
    List<SaleLine> lines = [];
    if (linesRaw is String && linesRaw.isNotEmpty) {
      final decoded = jsonDecode(linesRaw) as List<dynamic>;
      lines = decoded
          .map((e) => SaleLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (linesRaw is List) {
      lines = linesRaw
          .map((e) => SaleLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return SaleDetail(
      saleId: json.intField('SaleId') ?? 0,
      staffEmail: json.stringField('StaffEmail') ?? '',
      customer: json.stringField('Customer'),
      note: json.stringField('Note'),
      paymentTypeId: json.intField('PaymentTypeId'),
      orderRequestId: json.intField('OrderRequestId'),
      createdAt: createdAt,
      subtotalAmount: json.doubleField('SubtotalAmount'),
      totalAmount: json.doubleField('TotalAmount'),
      discountPercent: json.doubleField('DiscountPercent'),
      discountFixedAmount: json.doubleField('DiscountFixedAmount'),
      currencyId: json.intField('CurrencyId'),
      lines: lines,
    );
  }
}
