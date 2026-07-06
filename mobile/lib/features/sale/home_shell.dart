import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/screenshot_config.dart';
import '../auth/auth_provider.dart';
import '../auth/user_profile_provider.dart';
import 'cart_screen.dart';
import 'my_orders_list_screen.dart';
import 'orders_list_screen.dart';
import 'products_list_screen.dart';
import 'reports_screen.dart';
import 'sales_list_screen.dart';
import '../auth/profile_screen.dart';
import 'home_shell_tab_provider.dart';
import 'pending_cart_add_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    if (ScreenshotConfig.enabled && ScreenshotConfig.route == '/home') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(homeShellTabProvider.notifier).state = ScreenshotConfig.tabIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
      final wasLoggedIn = previous?.valueOrNull ?? false;
      final isLoggedIn = next.valueOrNull ?? false;
      if (!wasLoggedIn && isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final message = ref.read(pendingCartAddProvider.notifier).apply();
          if (message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        });
      }
    });

    final loggedIn = ref.watch(authStateProvider).valueOrNull ?? false;
    // Tour mode: profile API may lag; staff layout keeps tab indices stable.
    final isStaff = ScreenshotConfig.enabled && ScreenshotConfig.autoLogin
        ? true
        : ref.watch(isStaffProvider);

    final List<Widget> pages;
    final List<NavigationDestination> destinations;

    if (isStaff) {
      pages = const [
        ProductsListScreen(),
        OrdersListScreen(),
        CartScreen(),
        SalesListScreen(),
        ReportsScreen(),
        ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.storefront), label: 'Ürünler'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Talepler'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Sepet'),
        NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Satışlar'),
        NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Raporlar'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else if (loggedIn) {
      pages = const [
        ProductsListScreen(),
        MyOrdersListScreen(),
        CartScreen(),
        ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.storefront), label: 'Ürünler'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Taleplerim'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Sepet'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else {
      pages = const [
        ProductsListScreen(),
        ProfileScreen(),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.storefront), label: 'Ürünler'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }

    final tabIndex = ref.watch(homeShellTabProvider);
    final safeIndex = tabIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) =>
            ref.read(homeShellTabProvider.notifier).state = i,
        destinations: destinations,
      ),
    );
  }
}
