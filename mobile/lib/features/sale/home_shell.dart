import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/screenshot_config.dart';
import '../auth/profile_screen.dart';
import '../auth/user_profile_provider.dart';
import 'cart_screen.dart';
import 'orders_list_screen.dart';
import 'products_list_screen.dart';
import 'scanner_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = ScreenshotConfig.enabled && ScreenshotConfig.route == '/home'
      ? ScreenshotConfig.tabIndex
      : 0;

  @override
  Widget build(BuildContext context) {
    // Tour mode: profile API may lag; staff layout keeps tab indices stable.
    final isStaff = ScreenshotConfig.enabled && ScreenshotConfig.autoLogin
        ? true
        : ref.watch(isStaffProvider);
    final pages = isStaff
        ? const [
            ProductsListScreen(),
            OrdersListScreen(),
            CartScreen(),
            ScannerScreen(),
            ProfileScreen(),
          ]
        : const [
            ProductsListScreen(),
            CartScreen(),
            ProfileScreen(),
          ];

    final destinations = isStaff
        ? const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Ürünler'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Siparişler'),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Sepet'),
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Barkod'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Ürünler'),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Sepet'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          ];

    final safeIndex = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
