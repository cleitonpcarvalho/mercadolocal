import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';

class MercadoLocalDeliveryApp extends StatefulWidget {
  const MercadoLocalDeliveryApp({super.key});

  @override
  State<MercadoLocalDeliveryApp> createState() =>
      _MercadoLocalDeliveryAppState();
}

class _MercadoLocalDeliveryAppState extends State<MercadoLocalDeliveryApp> {
  late GoRouter _router;
  bool _routerReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routerReady) return;

    final AuthProvider authProvider = context.read<AuthProvider>();

    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        final bool isAuthenticated = authProvider.isAuthenticated;
        final String route = state.matchedLocation;

        final bool isProtected = route == '/home';
        if (isProtected && !isAuthenticated) {
          return '/login';
        }

        if ((route == '/login' || route == '/splash') && isAuthenticated) {
          return '/home';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/splash',
          builder: (BuildContext context, GoRouterState state) =>
              const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (BuildContext context, GoRouterState state) =>
              const HomeScreen(),
        ),
      ],
    );

    ApiService.setUnauthorizedHandler(() {
      _router.go('/login');
    });

    _routerReady = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_routerReady) {
      return const SizedBox.shrink();
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mercado Local Entregas',
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
