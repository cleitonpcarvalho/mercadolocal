import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/services/api_service.dart';
import 'core/services/navigation_service.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/store/store_screen.dart';

class MercadoLocalApp extends StatefulWidget {
  const MercadoLocalApp({super.key});

  @override
  State<MercadoLocalApp> createState() => _MercadoLocalAppState();
}

class _MercadoLocalAppState extends State<MercadoLocalApp> {
  late GoRouter _router;
  bool _routerReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routerReady) return;

    final AuthProvider authProvider = context.read<AuthProvider>();
    ApiService.setUnauthorizedHandler(authProvider.handleUnauthorized);

    _router = GoRouter(
      initialLocation: '/splash',
      navigatorKey: NavigationService.navigatorKey,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuthenticated = authProvider.isAuthenticated;
        final String route = state.matchedLocation;

        final bool isProtected =
            route == '/orders' ||
            route.startsWith('/orders/') ||
            route == '/profile';

        if (isProtected && !isAuthenticated) {
          final String next = Uri.encodeComponent(state.uri.toString());
          return '/login?next=$next';
        }

        final bool isAuthPage = route == '/login' || route == '/register';
        if (isAuthPage && isAuthenticated) {
          return '/home';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (BuildContext context, GoRouterState state) {
            final int id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return ProductDetailScreen(productId: id);
          },
        ),
        GoRoute(
          path: '/store/:id',
          builder: (BuildContext context, GoRouterState state) {
            final int id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return StoreScreen(storeId: id);
          },
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (BuildContext context, GoRouterState state) {
            final int id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return OrderTrackingScreen(orderId: id);
          },
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    NavigationService.setRouter(_router);
    _routerReady = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_routerReady) {
      return const SizedBox.shrink();
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mercado Local',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.gray50,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.white,
        ),
        textTheme: TextTheme(
          titleLarge: AppTextStyles.titleLarge,
          titleMedium: AppTextStyles.titleMedium,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.caption,
        ),
      ),
      routerConfig: _router,
    );
  }
}
