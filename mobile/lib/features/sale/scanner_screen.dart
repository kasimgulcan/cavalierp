import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/models/json_field.dart';
import 'cart_provider.dart';
import 'currency_provider.dart';
import 'currency_selection.dart';
import 'models/product.dart';
import 'widgets/product_dialog_image.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController();
  bool _scanLocked = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _ensureDefaultCurrency());
  }

  Future<void> _ensureDefaultCurrency() async {
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
    } catch (_) {
      // kDefaultCurrencyId ile devam
    }
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanLocked) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    _scanLocked = true;
    await _controller.stop();
    if (mounted) setState(() {});

    try {
      final product = await ref
          .read(cartProvider.notifier)
          .lookupBarcode(barcode);
      if (!mounted) return;

      if (product == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ürün bulunamadı')));
        return;
      }
      await _showAddDialog(product);
    } finally {
      if (mounted) {
        _scanLocked = false;
        await _controller.start();
        setState(() {});
      }
    }
  }

  Future<void> _showAddDialog(Product product) async {
    final currency = ref.read(selectedCurrencyProvider);
    final currencyCode = currency?.stringField('Code') ?? '';

    var quantity = 1;
    var price = product.unitPrice;
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
                  'Liste fiyatı ($currencyCode): ${product.listPrice.toStringAsFixed(2)}',
                ),
                Text('Stok: ${product.stockQty}'),
                Row(
                  children: [
                    const Text('Adet:'),
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
                TextFormField(
                  initialValue: price.toStringAsFixed(2),
                  decoration: InputDecoration(
                    labelText: 'Birim fiyat ($currencyCode)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => price = double.tryParse(v) ?? price,
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
    if (result == true) {
      ref
          .read(cartProvider.notifier)
          .addProduct(product, quantity: quantity, unitPrice: price);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sepete eklendi')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencies = ref.watch(currenciesProvider);
    final selectedCurrencyId = ref.watch(selectedCurrencyIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Sepet',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sepet sekmesinden görüntüleyin')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
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
                  key: ValueKey(effectiveValue),
                  decoration: const InputDecoration(
                    labelText: 'Para birimi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  initialValue: effectiveValue,
                  items: menuItems,
                  onChanged: menuItems.isEmpty ? null : _onCurrencyChanged,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                error.toString().replaceFirst('Exception: ', ''),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                if (_scanLocked)
                  const ColoredBox(
                    color: Colors.black45,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
