import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/json_field.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';
import 'models/sale.dart';
import 'models/sale_flags.dart';

const kSalePageSize = 30;

class SaleListFilter {
  const SaleListFilter({
    this.dateFrom,
    this.dateTo,
    this.flags = const {},
    this.onlyFlagged = false,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Set<SaleFlagKind> flags;
  final bool onlyFlagged;

  @override
  bool operator ==(Object other) =>
      other is SaleListFilter &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.onlyFlagged == onlyFlagged &&
      other.flags.length == flags.length &&
      other.flags.containsAll(flags);

  @override
  int get hashCode => Object.hash(
        dateFrom,
        dateTo,
        onlyFlagged,
        Object.hashAllUnordered(flags),
      );
}

class SaleListState {
  const SaleListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<SaleSummary> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  SaleListState copyWith({
    List<SaleSummary>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      SaleListState(
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

final saleListProvider = StateNotifierProvider.autoDispose
    .family<SaleListNotifier, SaleListState, SaleListFilter>((ref, filter) {
  final notifier = SaleListNotifier(ref.watch(spClientProvider), filter);
  ref.listen(authStateProvider, (prev, next) {
    if (next.valueOrNull == true && prev?.valueOrNull != true) {
      notifier.refresh();
    }
  });
  Future.microtask(notifier.refresh);
  return notifier;
});

class SaleListNotifier extends StateNotifier<SaleListState> {
  SaleListNotifier(this._client, this._filter) : super(const SaleListState());

  final SpClient _client;
  final SaleListFilter _filter;
  int _page = 0;

  Future<void> refresh() async {
    _page = 0;
    if (!mounted) return;
    state = const SaleListState(isLoading: true);
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
      final response = await _client.exec('Sale.List', {
        'DateFrom': _formatDate(_filter.dateFrom),
        'DateTo': _formatDate(_filter.dateTo),
        'Page': nextPage,
        'PageSize': kSalePageSize,
        ...saleListFlagParams(
          flags: _filter.flags,
          onlyFlagged: _filter.onlyFlagged,
        ),
      });
      if (!mounted) return;
      if (!response.success) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: response.error ?? 'Satışlar yüklenemedi',
        );
        return;
      }
      final batch = parseRowList(response.data)
          .map((row) => SaleSummary.fromJson(row))
          .toList();
      _page = nextPage;
      state = SaleListState(
        items: reset ? batch : [...state.items, ...batch],
        hasMore: batch.length >= kSalePageSize,
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

final saleDetailProvider = FutureProvider.autoDispose.family<SaleDetail, int>((ref, saleId) async {
  final client = ref.watch(spClientProvider);
  final response = await client.exec('Sale.Get', {'SaleId': saleId});
  if (!response.success) {
    throw Exception(response.error ?? 'Satış yüklenemedi');
  }
  final rows = parseRowList(response.data);
  if (rows.isEmpty) throw Exception('Satış bulunamadı');
  return SaleDetail.fromJson(rows.first);
});

class SaleRepository {
  SaleRepository(this._client);

  final SpClient _client;

  Future<bool> cancel({required int saleId}) async {
    final response = await _client.exec('Sale.Delete', {
      'SaleId': saleId,
    });
    return response.success;
  }

  Future<String?> setFlags({
    required int saleId,
    required SaleFlags flags,
  }) async {
    final response = await _client.exec('Sale.SetFlags', {
      'SaleId': saleId,
      ...flags.toParams(),
    });
    if (response.success) return null;
    return response.error ?? 'İşaret kaydedilemedi';
  }
}

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  return SaleRepository(ref.watch(spClientProvider));
});
