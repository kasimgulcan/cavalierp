import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'order_request_provider.dart';
import 'widgets/order_list_empty_state.dart';
import 'widgets/order_list_filter_bar.dart';
import 'widgets/order_request_list_card.dart';

class MyOrdersListScreen extends ConsumerStatefulWidget {
  const MyOrdersListScreen({super.key});

  @override
  ConsumerState<MyOrdersListScreen> createState() => _MyOrdersListScreenState();
}

class _MyOrdersListScreenState extends ConsumerState<MyOrdersListScreen> {
  final _scrollController = ScrollController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _status;
  late OrderListFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 90));
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
      ref.read(myOrderListProvider(_filter).notifier).loadMore();
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
    final state = ref.watch(myOrderListProvider(_filter));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Taleplerim')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OrderListFilterBar(
              dateFromLabel: _formatDisplayDate(_dateFrom),
              dateToLabel: _formatDisplayDate(_dateTo),
              status: _status,
              onPickDateFrom: () => _pickDate(isFrom: true),
              onPickDateTo: () => _pickDate(isFrom: false),
              onStatusChanged: (value) {
                setState(() => _status = value);
                _applyFilter();
              },
            ),
          ),
          if (!state.isLoading && state.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.items.length} talep',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(myOrderListProvider(_filter).notifier).refresh(),
              child: _buildBody(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          OrderListEmptyState(
            title: 'Talepler yüklenemedi',
            subtitle: state.error,
            icon: Icons.error_outline_rounded,
          ),
          Center(
            child: FilledButton(
              onPressed: () =>
                  ref.read(myOrderListProvider(_filter).notifier).refresh(),
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
          OrderListEmptyState(
            title: 'Henüz talep yok',
            subtitle:
                'Seçili tarih aralığında talep bulunamadı. Filtreleri genişletmeyi deneyin.',
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.items[index];

        return OrderRequestListCard(
          order: order,
          createdAtLabel: order.createdAt != null
              ? _formatDateTime(order.createdAt!.toLocal())
              : null,
          lineCount: order.lineCount,
          showStatusChip: true,
          onTap: () => context.push('/my-orders/${order.orderRequestId}'),
        );
      },
    );
  }
}
