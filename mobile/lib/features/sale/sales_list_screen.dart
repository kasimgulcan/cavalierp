import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'currency_display.dart';
import 'currency_provider.dart';
import 'models/sale_flags.dart';
import 'sale_provider.dart';
import 'widgets/order_list_empty_state.dart';
import 'widgets/sale_list_card.dart';
import 'widgets/sale_list_filter_bar.dart';
import 'widgets/sale_list_summary_card.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  final _scrollController = ScrollController();
  DateTime? _dateFrom;
  DateTime? _dateTo;
  SaleFlagKind? _flag;
  bool _onlyFlagged = false;
  late SaleListFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateFrom = DateTime(now.year, now.month, now.day);
    _dateTo = DateTime(now.year, now.month, now.day);
    _filter = _buildFilter();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  SaleListFilter _buildFilter() => SaleListFilter(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        flag: _flag,
        onlyFlagged: _onlyFlagged,
      );

  void _selectAll() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _flag = null;
      _onlyFlagged = false;
      _dateFrom ??= today;
      _dateTo ??= today;
    });
    _applyFilter();
  }

  void _selectFlag(SaleFlagKind flag) {
    setState(() {
      _flag = flag;
      _onlyFlagged = false;
      _dateFrom = null;
      _dateTo = null;
    });
    _applyFilter();
  }

  void _selectFlagged() {
    setState(() {
      _flag = null;
      _onlyFlagged = true;
      _dateFrom = null;
      _dateTo = null;
    });
    _applyFilter();
  }

  void _applyFilter() {
    setState(() => _filter = _buildFilter());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(saleListProvider(_filter).notifier).loadMore();
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
    if (date == null) return 'Tüm tarihler';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDisplayDate(dt)} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  double _sumLoadedTotal(SaleListState state) {
    return state.items.fold<double>(
      0,
      (sum, sale) => sum + (sale.totalAmount ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleListProvider(_filter));
    final currency = ref.watch(selectedCurrencyProvider);
    final symbol = currencySymbolFrom(currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Satışlar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SaleListFilterBar(
              dateFromLabel: _formatDisplayDate(_dateFrom),
              dateToLabel: _formatDisplayDate(_dateTo),
              onPickDateFrom: () => _pickDate(isFrom: true),
              onPickDateTo: () => _pickDate(isFrom: false),
              selectedFlag: _flag,
              onlyFlagged: _onlyFlagged,
              onSelectFlag: (flag) {
                if (flag == null) {
                  _selectAll();
                } else {
                  _selectFlag(flag);
                }
              },
              onSelectFlagged: _selectFlagged,
            ),
          ),
          if (!state.isLoading && state.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SaleListSummaryCard(
                saleCount: state.items.length,
                totalAmount: _sumLoadedTotal(state),
                hasMore: state.hasMore,
                symbol: symbol,
              ),
            ),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(saleListProvider(_filter).notifier).refresh(),
              child: _buildBody(context, state, symbol),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, SaleListState state, String symbol) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          OrderListEmptyState(
            title: 'Satışlar yüklenemedi',
            subtitle: state.error,
            icon: Icons.error_outline_rounded,
          ),
          Center(
            child: FilledButton(
              onPressed: () => ref.read(saleListProvider(_filter).notifier).refresh(),
              child: const Text('Tekrar dene'),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          OrderListEmptyState(
            title: _filter.flag != null || _filter.onlyFlagged
                ? 'Bu bayrakta satış yok'
                : 'Bu tarih aralığında satış yok',
            subtitle: _filter.flag != null || _filter.onlyFlagged
                ? 'Başka bir işaret seçmeyi veya tarihi daraltmayı deneyin.'
                : 'Farklı bir tarih aralığı seçmeyi deneyin.',
            icon: Icons.point_of_sale_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final sale = state.items[index];

        return SaleListCard(
          sale: sale,
          symbol: symbol,
          createdAtLabel: sale.createdAt != null
              ? _formatDateTime(sale.createdAt!.toLocal())
              : null,
          onTap: () async {
            await context.push('/sales/${sale.saleId}');
            if (mounted) {
              ref.read(saleListProvider(_filter).notifier).refresh();
            }
          },
        );
      },
    );
  }
}
