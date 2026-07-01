import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/order_request.dart';
import 'order_request_provider.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final _scrollController = ScrollController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _status;
  late OrderListFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    _dateTo = DateTime(now.year, now.month, now.day);
    _filter = _buildFilter();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  OrderListFilter _buildFilter() => OrderListFilter(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        status: _status,
      );

  void _applyFilter() {
    setState(() => _filter = _buildFilter());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(orderListProvider(_filter).notifier).loadMore();
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = DateTime(picked.year, picked.month, picked.day);
      } else {
        _dateTo = DateTime(picked.year, picked.month, picked.day);
      }
    });
    _applyFilter();
  }

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDisplayDate(dt)} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListProvider(_filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Siparişler')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: true),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_formatDisplayDate(_dateFrom)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: false),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_formatDisplayDate(_dateTo)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    isDense: true,
                  ),
                  initialValue: _status,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tümü')),
                    DropdownMenuItem(value: 'Pending', child: Text('Bekliyor')),
                    DropdownMenuItem(value: 'Accepted', child: Text('Onaylandı')),
                    DropdownMenuItem(value: 'Converted', child: Text('Tamamlandı')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Reddedildi')),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value);
                    _applyFilter();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(orderListProvider(_filter).notifier).refresh(),
              child: _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderListState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          Center(child: Text(state.error!)),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => ref.read(orderListProvider(_filter).notifier).refresh(),
              child: const Text('Tekrar dene'),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 48),
          Center(child: Text('Bu tarih aralığında sipariş yok')),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('#${order.orderRequestId} · ${order.displayName}'),
            subtitle: Text(
              [
                if (order.createdAt != null) _formatDateTime(order.createdAt!.toLocal()),
                orderStatusLabel(order.status),
                if (order.lineCount != null) '${order.lineCount} kalem',
              ].join(' · '),
            ),
            trailing: Text(
              order.totalAmount?.toStringAsFixed(2) ?? '—',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              await context.push('/orders/${order.orderRequestId}');
              if (mounted) {
                ref.read(orderListProvider(_filter).notifier).refresh();
              }
            },
          ),
        );
      },
    );
  }
}
