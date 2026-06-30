import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_field.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';
import 'models/product.dart';

const kProductPageSize = 30;

class ProductListFilter {
  const ProductListFilter({
    required this.currencyId,
    this.search = '',
  });

  final int currencyId;
  final String search;

  @override
  bool operator ==(Object other) =>
      other is ProductListFilter &&
      other.currencyId == currencyId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(currencyId, search);
}

class ProductListState {
  const ProductListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Product> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  ProductListState copyWith({
    List<Product>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) =>
      ProductListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
      );
}

final productListProvider = StateNotifierProvider.autoDispose
    .family<ProductListNotifier, ProductListState, ProductListFilter>((ref, filter) {
  final notifier = ProductListNotifier(ref.watch(spClientProvider), filter);
  ref.listen(authStateProvider, (prev, next) {
    if (next.valueOrNull == true && prev?.valueOrNull != true) {
      notifier.refresh();
    }
  });
  Future.microtask(notifier.refresh);
  return notifier;
});

class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier(this._client, this._filter) : super(const ProductListState());

  final SpClient _client;
  final ProductListFilter _filter;
  int _page = 0;

  Future<void> refresh() async {
    _page = 0;
    state = const ProductListState(isLoading: true);
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    final nextPage = reset ? 1 : _page + 1;
    try {
      final response = await _client.exec('Product.List', {
        'Search': _filter.search.isEmpty ? null : _filter.search,
        'CurrencyId': _filter.currencyId,
        'Page': nextPage,
        'PageSize': kProductPageSize,
      });
      if (!response.success) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: response.error ?? 'Ürünler yüklenemedi',
        );
        return;
      }
      final batch = parseRowList(response.data)
          .map((row) => Product.fromJson(row))
          .toList();
      _page = nextPage;
      state = ProductListState(
        items: reset ? batch : [...state.items, ...batch],
        hasMore: batch.length >= kProductPageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}
