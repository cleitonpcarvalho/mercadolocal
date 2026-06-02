import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../delivery/active_delivery_screen.dart';
import '../delivery/available_deliveries_screen.dart';
import '../delivery/delivery_history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  Timer? _availablePollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _availablePollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final DeliveryProvider deliveryProvider = context.read<DeliveryProvider>();

    await deliveryProvider.loadHistory();
    if (_isOnline) {
      await deliveryProvider.loadAvailable();
      _startAvailablePolling();
    }
  }

  void _startAvailablePolling() {
    _availablePollTimer?.cancel();

    _availablePollTimer = Timer.periodic(const Duration(seconds: 15), (
      _,
    ) async {
      if (!_isOnline) return;

      final DeliveryProvider deliveryProvider = context
          .read<DeliveryProvider>();
      await deliveryProvider.loadAvailable();
      await deliveryProvider.refreshActiveDelivery();
    });
  }

  void _stopAvailablePolling() {
    _availablePollTimer?.cancel();
    _availablePollTimer = null;
  }

  void _toggleOnline(bool value) async {
    setState(() {
      _isOnline = value;
    });

    final DeliveryProvider deliveryProvider = context.read<DeliveryProvider>();

    if (value) {
      await deliveryProvider.loadAvailable();
      _startAvailablePolling();
    } else {
      _stopAvailablePolling();
    }
  }

  void _goToActive() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _goToAvailable() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final String driverName = authProvider.user?.name ?? 'Entregador';

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              driverName,
              style: AppTextStyles.body.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: AppTextStyles.caption.copyWith(
                color: _isOnline ? AppColors.success : AppColors.gray500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            children: <Widget>[
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: AppTextStyles.caption.copyWith(
                  color: _isOnline ? AppColors.success : AppColors.gray500,
                ),
              ),
              Switch(
                value: _isOnline,
                activeThumbColor: AppColors.success,
                activeTrackColor: AppColors.success.withAlpha(70),
                onChanged: _toggleOnline,
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          AvailableDeliveriesScreen(
            isOnline: _isOnline,
            onAcceptedDelivery: _goToActive,
          ),
          ActiveDeliveryScreen(
            isOnline: _isOnline,
            onCompletedDelivery: _goToAvailable,
          ),
          const DeliveryHistoryScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.gray500,
        backgroundColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Disponíveis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            label: 'Ativa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
