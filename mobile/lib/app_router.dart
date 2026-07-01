import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/config/screenshot_config.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/privacy_policy_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/sale/cart_screen.dart';
import 'features/sale/checkout_screen.dart';
import 'features/sale/order_checkout_screen.dart';
import 'features/sale/order_confirmed_screen.dart';
import 'features/sale/home_shell.dart';
import 'features/sale/order_detail_screen.dart';
import 'features/sale/sale_summary_screen.dart';

const _authRequiredPrefixes = [
  '/checkout',
  '/order-checkout',
  '/order-confirmed',
  '/sale-summary',
  '/orders/',
];

bool _requiresAuth(String location) =>
    _authRequiredPrefixes.any(location.startsWith);

String _loginRedirect(String returnPath) {
  final encoded = Uri.encodeComponent(returnPath);
  return '/login?redirect=$encoded';
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation:
        ScreenshotConfig.enabled ? ScreenshotConfig.route : '/home',
    redirect: (context, state) {
      final isLoading = auth.isLoading;
      if (isLoading) return null;

      final loggedIn = auth.valueOrNull == true;
      final location = state.matchedLocation;
      final onAuth = location == '/login' || location == '/register';
      final isPublic =
          onAuth || location == '/privacy' || location == '/home';

      if (!loggedIn && _requiresAuth(location)) {
        return _loginRedirect(state.uri.path);
      }
      if (!loggedIn && !isPublic) return '/home';
      if (loggedIn && onAuth) {
        final redirect = state.uri.queryParameters['redirect'];
        if (redirect != null && redirect.isNotEmpty) return redirect;
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/privacy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/order-checkout', builder: (context, state) => const OrderCheckoutScreen()),
      GoRoute(
        path: '/order-confirmed',
        builder: (context, state) =>
            OrderConfirmedScreen(order: state.extra! as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/sale-summary',
        builder: (context, state) =>
            SaleSummaryScreen(sale: state.extra! as Map<String, dynamic>),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          orderRequestId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
