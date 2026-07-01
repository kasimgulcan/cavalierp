import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import 'models/order_request.dart';
import 'order_request_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderRequestId});

  final int orderRequestId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final _customer = TextEditingController();
  final _note = TextEditingController();
  int? _paymentTypeId;
  bool _saving = false;
  bool _converting = false;
  List<OrderRequestLine>? _editableLines;

  @override
  void dispose() {
    _customer.dispose();
    _note.dispose();
    super.dispose();
  }

  void _initFromDetail(OrderRequestDetail detail) {
    if (_editableLines != null) return;
    _customer.text = detail.customer ?? '';
    _note.text = detail.note ?? '';
    _editableLines = detail.lines.map((l) => l.copyWith()).toList();
  }

  Future<void> _save(OrderRequestDetail detail) async {
    final lines = _editableLines;
    if (lines == null || lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kalem olmalı')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(orderRequestRepositoryProvider);
    final result = await repo.update(
      orderRequestId: detail.orderRequestId,
      customer: _customer.text.trim(),
      note: _note.text.trim(),
      lines: lines.map((l) => l.toPayload()).toList(),
    );
    setState(() => _saving = false);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi')),
      );
      return;
    }

    _editableLines = null;
    ref.invalidate(orderDetailProvider(widget.orderRequestId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sipariş güncellendi')),
    );
  }

  Future<void> _reject(OrderRequestDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi reddet'),
        content: const Text('Bu sipariş talebi reddedilecek. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reddet')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final repo = ref.read(orderRequestRepositoryProvider);
    final result = await repo.update(
      orderRequestId: detail.orderRequestId,
      status: 'Rejected',
    );
    setState(() => _saving = false);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reddedilemedi')),
      );
      return;
    }

    _editableLines = null;
    ref.invalidate(orderDetailProvider(widget.orderRequestId));
  }

  Future<void> _convert(OrderRequestDetail detail) async {
    final lowStock = (_editableLines ?? detail.lines)
        .where((l) => (l.stockQty ?? 0) < l.quantity)
        .toList();
    if (lowStock.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yetersiz stok: ${lowStock.map((l) => l.product).join(', ')}',
          ),
        ),
      );
      return;
    }

    setState(() => _converting = true);

    if (detail.isEditable && _editableLines != null) {
      final repo = ref.read(orderRequestRepositoryProvider);
      final saved = await repo.update(
        orderRequestId: detail.orderRequestId,
        customer: _customer.text.trim(),
        note: _note.text.trim(),
        lines: _editableLines!.map((l) => l.toPayload()).toList(),
      );
      if (saved == null) {
        setState(() => _converting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kaydedilemedi, satış tamamlanamadı')),
          );
        }
        return;
      }
    }

    final repo = ref.read(orderRequestRepositoryProvider);
    final result = await repo.convert(
      orderRequestId: detail.orderRequestId,
      paymentTypeId: _paymentTypeId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    setState(() => _converting = false);
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış tamamlanamadı (stok yetersiz olabilir)')),
      );
      return;
    }

    ref.invalidate(orderDetailProvider(widget.orderRequestId));
    context.go('/sale-summary', extra: result);
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final lines = _editableLines!;
      final newQty = lines[index].quantity + delta;
      if (newQty <= 0) {
        lines.removeAt(index);
      } else {
        lines[index].quantity = newQty;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(orderDetailProvider(widget.orderRequestId));
    final paymentTypes = ref.watch(_paymentTypesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Sipariş #${widget.orderRequestId}')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(orderDetailProvider(widget.orderRequestId)),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
        data: (detail) {
          _initFromDetail(detail);
          final lines = _editableLines ?? detail.lines;
          final editable = detail.isEditable;
          final total = lines.fold(0.0, (sum, l) => sum + l.computedTotal);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(detail.memberEmail),
                      subtitle: Text(
                        [
                          orderStatusLabel(detail.status),
                          if (detail.createdAt != null)
                            _formatDateTime(detail.createdAt!.toLocal()),
                        ].join(' · '),
                      ),
                      trailing: Chip(label: Text(orderStatusLabel(detail.status))),
                    ),
                    if (editable) ...[
                      TextField(
                        controller: _customer,
                        decoration: const InputDecoration(labelText: 'Müşteri'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _note,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Not'),
                      ),
                    ] else ...[
                      if (detail.customer != null && detail.customer!.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Müşteri'),
                          subtitle: Text(detail.customer!),
                        ),
                      if (detail.note != null && detail.note!.isNotEmpty)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Not'),
                          subtitle: Text(detail.note!),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text('Kalemler', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...List.generate(lines.length, (index) {
                      final line = lines[index];
                      final lowStock = (line.stockQty ?? 0) < line.quantity;
                      return Card(
                        child: ListTile(
                          title: Text(line.product),
                          subtitle: Text(
                            'Stok: ${line.stockQty ?? '?'} · Birim: ${line.unitPrice.toStringAsFixed(2)}',
                            style: lowStock
                                ? TextStyle(color: Theme.of(context).colorScheme.error)
                                : null,
                          ),
                          trailing: editable
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => _updateQuantity(index, -1),
                                    ),
                                    Text('${line.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => _updateQuantity(index, 1),
                                    ),
                                  ],
                                )
                              : Text('${line.quantity} x ${line.computedTotal.toStringAsFixed(2)}'),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Toplam: ${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (editable && detail.status != 'Converted') ...[
                      const SizedBox(height: 16),
                      paymentTypes.when(
                        data: (items) => DropdownButtonFormField<int?>(
                          decoration: const InputDecoration(labelText: 'Ödeme tipi (satış için)'),
                          initialValue: _paymentTypeId,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Seçilmedi')),
                            ...items.map(
                              (p) => DropdownMenuItem(
                                value: (p['PaymentTypeId'] as num).toInt(),
                                child: Text(p['Name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _paymentTypeId = v),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              if (editable) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => _reject(detail),
                          child: const Text('Reddet'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _saving ? null : () => _save(detail),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _converting ? null : () => _convert(detail),
                      child: _converting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Satışı Tamamla (Stok Çıkışı)'),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

final _paymentTypesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('Lookup.PaymentTypes', {});
  if (!response.success) return [];
  return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});
