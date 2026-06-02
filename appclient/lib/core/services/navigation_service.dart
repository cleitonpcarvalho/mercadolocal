import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter? _router;

  static void setRouter(GoRouter router) {
    _router = router;
  }

  static void goToLogin() {
    _router?.go('/login');
  }
}
