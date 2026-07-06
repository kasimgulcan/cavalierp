import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_field.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';
import 'models/order_request.dart';
import 'order_request_images.dart';

const kOrderPageSize = 30;

class OrderListFilter {
  const OrderListFilter({
    this.dateFrom,
    this.dateTo,
    this.status,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? status;

  @override
  bool operator ==(Object other) =>
      other is OrderListFilter &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.status == status;

  @override
  int get hashCode => Object.hash(dateFrom, dateTo, status);
}

class OrderListState {
  const OrderListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<OrderRequestSummary> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  OrderListState copyWith({
    List<OrderRequestSummary>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      OrderListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

final orderListProvider = StateNotifierProvider.autoDispose
    .family<OrderListNotifier, OrderListState, OrderListFilter>((ref, filter) {
  final notifier = OrderListNotifier(
    ref.watch(spClientProvider),
    filter,
    listAlias: 'OrderRequest.List',
  );
  ref.listen(authStateProvider, (prev, next) {
    if (next.valueOrNull == true && prev?.valueOrNull != true) {
      notifier.refresh();
    }
  });
  Future.microtask(notifier.refresh);
  return notifier;
});

final myOrderListProvider = StateNotifierProvider.autoDispose
    .family<OrderListNotifier, OrderListState, OrderListFilter>((ref, filter) {
  final notifier = OrderListNotifier(
    ref.watch(spClientProvider),
    filter,
    listAlias: 'OrderRequest.ListMine',
  );
  ref.listen(authStateProvider, (prev, next) {
    if (next.valueOrNull == true && prev?.valueOrNull != true) {
      notifier.refresh();
    }
  });
  Future.microtask(notifier.refresh);
  return notifier;
});

class OrderListNotifier extends StateNotifier<OrderListState> {
  OrderListNotifier(this._client, this._filter, {required this.listAlias})
      : super(const OrderListState());

  final SpClient _client;
  final OrderListFilter _filter;
  final String listAlias;
  int _page = 0;

  Future<void> refresh() async {
    _page = 0;
    if (!mounted) return;
    state = const OrderListState(isLoading: true);
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (!mounted) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    final nextPage = reset ? 1 : _page + 1;
    try {
      final response = await _client.exec(listAlias, {
        'DateFrom': _formatDate(_filter.dateFrom),
        'DateTo': _formatDate(_filter.dateTo),
        'Status': _filter.status,
        'Page': nextPage,
        'PageSize': kOrderPageSize,
      });
      if (!mounted) return;
      if (!response.success) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: response.error ?? 'Talepler yüklenemedi',
        );
        return;
      }
      final batch = parseRowList(response.data)
          .map((row) => OrderRequestSummary.fromJson(row))
          .toList();
      _page = nextPage;
      state = OrderListState(
        items: reset ? batch : [...state.items, ...batch],
        hasMore: batch.length >= kOrderPageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}

final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderRequestDetail, int>((ref, orderRequestId) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('OrderRequest.Get', {
    'OrderRequestId': orderRequestId,
  });
  if (!response.success) {
    throw Exception(response.error ?? 'Talep yüklenemedi');
  }
  final rows = parseRowList(response.data);
  if (rows.isEmpty) throw Exception('Talep bulunamadı');
  final detail = OrderRequestDetail.fromJson(rows.first);
  final enrichedLines = await enrichOrderRequestLinesWithImages(client, detail.lines);
  return OrderRequestDetail(
    orderRequestId: detail.orderRequestId,
    memberEmail: detail.memberEmail,
    customer: detail.customer,
    note: detail.note,
    status: detail.status,
    createdAt: detail.createdAt,
    totalAmount: detail.totalAmount,
    currencyId: detail.currencyId,
    convertedSaleId: detail.convertedSaleId,
    convertedSaleDiscountPercent: detail.convertedSaleDiscountPercent,
    convertedSaleDiscountFixedAmount: detail.convertedSaleDiscountFixedAmount,
    convertedSaleSubtotalAmount: detail.convertedSaleSubtotalAmount,
    convertedSaleNetTotalAmount: detail.convertedSaleNetTotalAmount,
    lines: enrichedLines,
  );
});

final myOrderDetailProvider = FutureProvider.autoDispose
    .family<OrderRequestDetail, int>((ref, orderRequestId) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('OrderRequest.GetMine', {
    'OrderRequestId': orderRequestId,
  });
  if (!response.success) {
    throw Exception(response.error ?? 'Talep yüklenemedi');
  }
  final rows = parseRowList(response.data);
  if (rows.isEmpty) throw Exception('Talep bulunamadı');
  final detail = OrderRequestDetail.fromJson(rows.first);
  final enrichedLines = await enrichOrderRequestLinesWithImages(client, detail.lines);
  return OrderRequestDetail(
    orderRequestId: detail.orderRequestId,
    memberEmail: detail.memberEmail,
    customer: detail.customer,
    note: detail.note,
    status: detail.status,
    createdAt: detail.createdAt,
    totalAmount: detail.totalAmount,
    currencyId: detail.currencyId,
    convertedSaleId: detail.convertedSaleId,
    convertedSaleDiscountPercent: detail.convertedSaleDiscountPercent,
    convertedSaleDiscountFixedAmount: detail.convertedSaleDiscountFixedAmount,
    convertedSaleSubtotalAmount: detail.convertedSaleSubtotalAmount,
    convertedSaleNetTotalAmount: detail.convertedSaleNetTotalAmount,
    lines: enrichedLines,
  );
});

class OrderRequestMutationResult {
  const OrderRequestMutationResult._({this.data, this.error});

  factory OrderRequestMutationResult.success(Map<String, dynamic> data) =>
      OrderRequestMutationResult._(data: data);

  factory OrderRequestMutationResult.failure(String error) =>
      OrderRequestMutationResult._(error: error);

  final Map<String, dynamic>? data;
  final String? error;

  bool get ok => data != null;
}

class OrderRequestRepository {
  OrderRequestRepository(this._client);

  final SpClient _client;

  Future<Map<String, dynamic>?> update({
    required int orderRequestId,
    String? customer,
    String? note,
    String? status,
    List<Map<String, dynamic>>? lines,
  }) async {
    final response = await _client.exec('OrderRequest.Update', {
      'OrderRequestId': orderRequestId,
      'Customer': ?customer,
      'Note': ?note,
      'Status': ?status,
      'Lines': ?lines,
    });
    if (!response.success) return null;
    final rows = parseRowList(response.data);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<OrderRequestMutationResult> convert({
    required int orderRequestId,
    int? paymentTypeId,
    String? note,
  }) async {
    final response = await _client.exec('OrderRequest.Convert', {
      'OrderRequestId': orderRequestId,
      'PaymentTypeId': ?paymentTypeId,
      'Note': ?note,
    });
    if (!response.success) {
      return OrderRequestMutationResult.failure(
        response.error ?? 'Satış tamamlanamadı',
      );
    }
    final rows = parseRowList(response.data);
    if (rows.isEmpty) {
      return OrderRequestMutationResult.failure('Sunucu boş yanıt döndü');
    }
    return OrderRequestMutationResult.success(rows.first);
  }
}

final orderRequestRepositoryProvider = Provider<OrderRequestRepository>((ref) {
  return OrderRequestRepository(ref.watch(spClientProvider));
});
