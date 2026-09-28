import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_field.dart';
import '../../core/network/sp_client.dart';
import '../auth/auth_provider.dart';
import 'models/product.dart';
import 'turkish_search.dart';

const kProductPageSize = 30;

class ProductListFilter {
  const ProductListFilter({
    this.search = '',
  });

  final String search;

  @override
  bool operator ==(Object other) =>
      other is ProductListFilter && other.search == search;

  @override
  int get hashCode => search.hashCode;
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
    if (!mounted) return;
    state = const ProductListState(isLoading: true);
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
    final searches = _filter.search.isEmpty
        ? const <String?>[null]
        : turkishISearchVariants(_filter.search);
    try {
      final responses = await Future.wait(
        searches.map(
          (search) => _client.exec(
            'Product.List',
            {
              'Search': search == null || search.isEmpty ? null : search,
              'Page': nextPage,
              'PageSize': kProductPageSize,
            },
            auth: false,
          ),
        ),
      );
      if (!mounted) return;
      for (final response in responses) {
        if (!response.success) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            error: response.error ?? 'Ürünler yüklenemedi',
          );
          return;
        }
      }

      final seen = <int>{
        if (!reset) ...state.items.map((product) => product.sizeId),
      };
      final batch = <Product>[];
      var hasMore = false;
      for (final response in responses) {
        final rows = parseRowList(response.data)
            .map((row) => Product.fromJson(row))
            .toList();
        if (rows.length >= kProductPageSize) hasMore = true;
        for (final product in rows) {
          if (seen.add(product.sizeId)) batch.add(product);
        }
      }

      _page = nextPage;
      if (!mounted) return;
      state = ProductListState(
        items: reset ? batch : [...state.items, ...batch],
        hasMore: hasMore,
      );
      _scheduleImageEnrichment(batch);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  void _scheduleImageEnrichment(List<Product> batch) {
    if (!batch.any((product) => product.imageUrl?.trim().isNotEmpty != true)) {
      return;
    }
    // Ürün listesi önce gösterilir; görsel URL'leri arka planda tamamlanır.
    Future<void>(() => _enrichMissingImages());
  }

  Future<void> _enrichMissingImages() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (!mounted) return;
      if (!state.items
          .any((product) => product.imageUrl?.trim().isNotEmpty != true)) {
        return;
      }

      try {
        final response = await _client.exec('Product.Images', {}, auth: false);
        if (!response.success || !mounted) return;

        final imageByCode = <String, String>{};
        for (final row in parseRowList(response.data)) {
          final code = row.stringField('ProductCode')?.trim();
          final url = row.stringField('ImageUrl')?.trim();
          if (code == null || code.isEmpty || url == null || url.isEmpty) {
            continue;
          }
          imageByCode.putIfAbsent(code, () => url);
        }

        if (imageByCode.isNotEmpty) {
          final updated = state.items
              .map((product) {
                final existing = product.imageUrl?.trim();
                if (existing != null && existing.isNotEmpty) return product;
                final code = product.productCode?.trim();
                if (code == null || code.isEmpty) return product;
                final url = imageByCode[code];
                if (url == null || url.isEmpty) return product;
                return product.copyWith(imageUrl: url);
              })
              .toList();

          if (!mounted) return;
          state = state.copyWith(items: updated);
          return;
        }
      } catch (_) {
        return;
      }

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }
}
