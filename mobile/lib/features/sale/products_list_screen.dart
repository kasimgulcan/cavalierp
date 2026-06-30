import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_field.dart';
import 'cart_provider.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'models/product.dart';
import 'product_list_provider.dart';
import 'widgets/product_dialog_image.dart';
import 'widgets/product_thumbnail.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(_syncCurrencyFromList);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final filter = _currentFilter;
      ref.read(productListProvider(filter).notifier).loadMore();
    }
  }

  ProductListFilter get _currentFilter => ProductListFilter(
    currencyId: effectiveCurrencyId(ref.read(selectedCurrencyIdProvider)),
    search: _search,
  );

  Future<void> _syncCurrencyFromList() async {
    try {
      final currencies = await ref.read(currenciesProvider.future);
      if (!mounted || currencies.isEmpty) return;
      final current = ref.read(selectedCurrencyIdProvider);
      final hasCurrent = currencies.any(
        (c) => c.intField('CurrencyId') == current,
      );
      if (hasCurrent) return;
      final firstId =
          currencies.first.intField('CurrencyId') ?? kDefaultCurrencyId;
      ref.read(selectedCurrencyIdProvider.notifier).state = firstId;
    } catch (_) {}
  }

  void _onCurrencyChanged(int? currencyId) {
    if (currencyId == null) return;
    final cart = ref.read(cartProvider);
    if (cart.isNotEmpty) {
      ref.read(cartProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Para birimi değişti, sepet temizlendi')),
      );
    }
    ref.read(selectedCurrencyIdProvider.notifier).state = currencyId;
  }

  Future<void> _addProduct(Product product) async {
    var quantity = 1;
    final currency = ref.read(selectedCurrencyProvider);
    final currencyCode = currency?.stringField('Code') ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(product.displayName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductDialogImage(product: product),
                const SizedBox(height: 12),
                Text('ID: ${product.sizeId}'),
                Text(
                  'Fiyat ($currencyCode): ${product.unitPrice.toStringAsFixed(2)}',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setLocal(
                        () => quantity = (quantity - 1).clamp(1, 9999),
                      ),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: () => setLocal(() => quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sepete Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ref.read(cartProvider.notifier).addProduct(product, quantity: quantity);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sepete eklendi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencies = ref.watch(currenciesProvider);
    final selectedCurrencyId = ref.watch(selectedCurrencyIdProvider);
    final filter = ProductListFilter(
      currencyId: effectiveCurrencyId(selectedCurrencyId),
      search: _search,
    );
    final listState = ref.watch(productListProvider(filter));

    return Scaffold(
      appBar: AppBar(title: const Text('Ürünler')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: currencies.when(
              data: (items) {
                final menuItems = items
                    .map((c) {
                      final id = c.intField('CurrencyId');
                      if (id == null) return null;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(
                          '${c.stringField('Code')} — ${c.stringField('Name')}',
                        ),
                      );
                    })
                    .whereType<DropdownMenuItem<int>>()
                    .toList();

                final validIds = menuItems.map((e) => e.value).toSet();
                final current = selectedCurrencyId;
                final effectiveValue = validIds.contains(current)
                    ? current
                    : (menuItems.isNotEmpty
                          ? menuItems.first.value!
                          : kDefaultCurrencyId);

                if (!validIds.contains(current) && menuItems.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    ref.read(selectedCurrencyIdProvider.notifier).state =
                        effectiveValue;
                  });
                }

                return DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Para birimi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: menuItems,
                  onChanged: menuItems.isEmpty ? null : _onCurrencyChanged,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün veya barkod ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => setState(() => _search = v.trim()),
              onChanged: (v) {
                if (v.isEmpty && _search.isNotEmpty) {
                  setState(() => _search = '');
                }
              },
            ),
          ),
          Expanded(child: _buildProductList(listState, filter)),
        ],
      ),
    );
  }

  Widget _buildProductList(
    ProductListState listState,
    ProductListFilter filter,
  ) {
    if (listState.isLoading && listState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (listState.error != null && listState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(listState.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  ref.read(productListProvider(filter).notifier).refresh(),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (listState.items.isEmpty) {
      return const Center(child: Text('Ürün bulunamadı'));
    }

    final showLoader = listState.isLoadingMore;
    final itemCount = listState.items.length + (showLoader ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(productListProvider(filter).notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (context, index) {
          if (index >= listState.items.length - 1) {
            return const SizedBox.shrink();
          }
          return const Divider(height: 1);
        },
        itemBuilder: (context, index) {
          if (index >= listState.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final product = listState.items[index];
          return ListTile(
            leading: ProductThumbnail(imageUrl: product.imageUrl),
            title: Text(product.displayName),
            subtitle: Text(
              'ID: ${product.sizeId} · ${product.unitPrice.toStringAsFixed(2)} · Stok: ${product.stockQty.toStringAsFixed(0)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () => _addProduct(product),
            ),
            onTap: () => _addProduct(product),
          );
        },
      ),
    );
  }
}
