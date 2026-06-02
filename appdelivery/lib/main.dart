import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/api_service.dart';
import 'core/services/location_service.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.hydrateAccessToken();
  await _requestStartupPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..loadUser(),
        ),
        ChangeNotifierProvider<DeliveryProvider>(
          create: (_) => DeliveryProvider(),
        ),
      ],
      child: const MercadoLocalDeliveryApp(),
    ),
  );
}

Future<void> _requestStartupPermissions() async {
  try {
    await LocationService.requestPermission();
  } catch (_) {
    // Missing platform permission definitions should not block app startup.
  }

  try {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {
    // Firebase can be configured later without blocking app startup.
  }
}
