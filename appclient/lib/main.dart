import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider()..loadUser(),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ],
      child: const MercadoLocalApp(),
    ),
  );
}
