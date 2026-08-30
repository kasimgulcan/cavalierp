import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/format/price_format.dart';
import '../../core/models/json_field.dart';
import '../../core/network/api_error.dart';
import '../auth/auth_provider.dart';
import '../auth/user_profile_provider.dart';
import 'cart_provider.dart';
import 'currency_display.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'models/product.dart';
import 'models/product_group.dart';
import 'product_list_provider.dart';
import 'home_shell_tab_provider.dart';
import 'pending_cart_add_provider.dart';
import 'scanner_screen.dart';
import 'stock_provider.dart';
import 'widgets/currency_picker_bar.dart';
import 'widgets/product_group_list_tile.dart';
import 'widgets/product_size_sheet.dart';
import 'widgets/product_dialog_image.dart';
import 'widgets/quantity_stepper.dart';
import 'widgets/stock_warning_banner.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _search = '';
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
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

  ProductListFilter get _currentFilter => ProductListFilter(search: _search);

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
    ref.read(selectedCurrencyIdProvider.notifier).state = currencyId;
  }

  Future<void> _addProduct(
    Product product, {
    int? quantity,
    bool showSnackBar = true,
  }) async {
    final loggedIn = ref.read(authStateProvider).valueOrNull ?? false;
    if (!loggedIn) {
      if (quantity == null) return;
      ref.read(pendingCartAddProvider.notifier).queue(product, quantity);
      if (!mounted) return;
      final encoded = Uri.encodeComponent('/home');
      context.push('/login?redirect=$encoded');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giriş yaptıktan sonra sepetinize eklenecek'),
        ),
      );
      return;
    }

    if (quantity != null) {
      ref.read(cartProvider.notifier).addProduct(product, quantity: quantity);
      if (!mounted) return;
      if (showSnackBar) {
        _showCartSnackBar(product, quantity);
      }
      return;
    }

    var selectedQuantity = 1;
    final currency = ref.read(selectedCurrencyProvider);
    final currencySign = currencySymbolFrom(currency);
    final isStaff = ref.read(isStaffProvider);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(product.productName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProductDialogImage(imageUrl: product.imageUrl),
                const SizedBox(height: 12),
                Text('ID: ${product.sizeId}'),
                Text(
                  'Fiyat ($currencySign): ${formatPrice(product.priceFor(effectiveCurrencyId(ref.read(selectedCurrencyIdProvider))))}',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setLocal(
                        () => selectedQuantity = (selectedQuantity - 1).clamp(
                          1,
                          9999,
                        ),
                      ),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$selectedQuantity'),
                    IconButton(
                      onPressed: () => setLocal(() => selectedQuantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (StockWarningBanner.messageFor(
                  stockQty: product.stockQty,
                  quantity: selectedQuantity,
                  isStaff: isStaff,
                ).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  StockWarningBanner(
                    message: StockWarningBanner.messageFor(
                      stockQty: product.stockQty,
                      quantity: selectedQuantity,
                      isStaff: isStaff,
                    ),
                  ),
                ],
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
      ref
          .read(cartProvider.notifier)
          .addProduct(product, quantity: selectedQuantity);
      _showCartSnackBar(product, selectedQuantity);
    }
  }

  void _showCartSnackBar(Product product, int quantity) {
    final isStaff = ref.read(isStaffProvider);
    final message = StockWarningBanner.cartSnackBarMessage(
      stockQty: product.stockQty,
      quantity: quantity,
      isStaff: isStaff,
    );
    final hasStockWarning = StockWarningBanner.messageFor(
      stockQty: product.stockQty,
      quantity: quantity,
      isStaff: isStaff,
    ).isNotEmpty;
    showAppSnackBar(
      context,
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: hasStockWarning ? 4 : 2),
      ),
    );
  }

  Future<void> _addStock(Product product) async {
    var quantity = 1;
    final quantityStepperKey = GlobalKey<QuantityStepperState>();
    final noteController = TextEditingController();

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(product.productName),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProductDialogImage(imageUrl: product.imageUrl),
                  const SizedBox(height: 12),
                  Text('ID: ${product.sizeId}'),
                  Text('Mevcut stok: ${product.stockQty.toStringAsFixed(0)}'),
                  const SizedBox(height: 12),
                  const Text('Giriş miktarı'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: QuantityStepper(
                      key: quantityStepperKey,
                      value: quantity,
                      allowDirectInput: true,
                      onChanged: (value) => setLocal(() => quantity = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Not (isteğe bağlı)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
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
                onPressed: () {
                  quantity =
                      quantityStepperKey.currentState?.ensureCommitted() ??
                      quantity;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Stok Ekle'),
              ),
            ],
          ),
        ),
      );

      final note = noteController.text.trim();
      if (result != true || !mounted) return;

      final newStock = await ref
          .read(stockRepositoryProvider)
          .addEntry(
            sizeId: product.sizeId,
            quantity: quantity,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      await ref.read(productListProvider(_currentFilter).notifier).refresh();
      if (!mounted) return;
      final stockText = newStock != null
          ? newStock.toStringAsFixed(0)
          : (product.stockQty + quantity).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok girişi yapıldı. Güncel stok: $stockText')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      noteController.dispose();
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    if (_search.isEmpty) return;
    setState(() => _search = '');
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.isEmpty) {
      setState(() => _search = '');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _search = value.trim());
    });
  }

  Future<void> _openProductGroup(
    ProductGroup group,
    bool isStaff,
    String currencySign,
  ) async {
    await showProductSizeSheet(
      context: context,
      group: group,
      currencySymbol: currencySign,
      currencyId: effectiveCurrencyId(ref.read(selectedCurrencyIdProvider)),
      isStaff: isStaff,
      loggedIn: ref.read(authStateProvider).valueOrNull ?? false,
      onAddToCart: (product, quantity) =>
          _addProduct(product, quantity: quantity, showSnackBar: false),
      onAddStock: isStaff ? _addStock : null,
      onGoToCart: () => ref.read(homeShellTabProvider.notifier).state =
          kHomeShellCartTabIndex,
    );
    if (!mounted) return;
    _clearSearch();
  }

  void _openBarcodeScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ScannerScreen(showCurrencyPicker: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = ref.watch(isStaffProvider);
    final currencySign = currencySymbolFrom(
      ref.watch(selectedCurrencyProvider),
    );
    final currencyId = effectiveCurrencyId(
      ref.watch(selectedCurrencyIdProvider),
    );
    final filter = ProductListFilter(search: _search);
    final listState = ref.watch(productListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: CurrencyPickerBar(onChanged: _onCurrencyChanged),
            ),
          ),
        ],
      ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: _openBarcodeScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Barkodla sepete ekle'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Stil, ürün adı veya barkod ara',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                ),
                onSubmitted: (v) {
                  _searchDebounce?.cancel();
                  setState(() => _search = v.trim());
                },
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          Expanded(
            child: _buildProductList(
              listState,
              filter,
              isStaff,
              currencySign,
              currencyId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(
    ProductListState listState,
    ProductListFilter filter,
    bool isStaff,
    String currencySign,
    int currencyId,
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

    final groups = ProductGroup.fromProducts(listState.items);
    final showLoader = listState.isLoadingMore;
    final itemCount = groups.length + (showLoader ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => ref.read(productListProvider(filter).notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: itemCount,
        separatorBuilder: (_, index) {
          if (index >= groups.length - 1) {
            return const SizedBox.shrink();
          }
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          if (index >= groups.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final group = groups[index];
          return ProductGroupListTile(
            group: group,
            currencySymbol: currencySign,
            currencyId: currencyId,
            onTap: () => _openProductGroup(group, isStaff, currencySign),
          );
        },
      ),
    );
  }
}
