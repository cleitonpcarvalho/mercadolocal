import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/location_service.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/delivery/delivery_card.dart';

class AvailableDeliveriesScreen extends StatefulWidget {
  const AvailableDeliveriesScreen({
    required this.isOnline,
    required this.onAcceptedDelivery,
    super.key,
  });

  final bool isOnline;
  final VoidCallback onAcceptedDelivery;

  @override
  State<AvailableDeliveriesScreen> createState() =>
      _AvailableDeliveriesScreenState();
}

class _AvailableDeliveriesScreenState extends State<AvailableDeliveriesScreen> {
  final LocationService _locationService = const LocationService();

  Timer? _pollTimer;
  Position? _driverPosition;
  int? _acceptingDeliveryId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant AvailableDeliveriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _refreshAvailable();
        _startPolling();
      } else {
        _stopPolling();
      }
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadDriverLocation();

    if (widget.isOnline) {
      await _refreshAvailable();
      _startPolling();
    }
  }

  Future<void> _loadDriverLocation() async {
    final Position? position = await _locationService.getCurrentPosition();
    if (!mounted || position == null) return;

    setState(() {
      _driverPosition = position;
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (widget.isOnline) {
        _refreshAvailable();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshAvailable() async {
    final DeliveryProvider provider = context.read<DeliveryProvider>();
    await provider.loadAvailable();
  }

  Future<void> _accept(int id) async {
    setState(() {
      _acceptingDeliveryId = id;
    });

    final DeliveryProvider provider = context.read<DeliveryProvider>();

    try {
      await provider.acceptDelivery(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Entrega aceita com sucesso.'),
        ),
      );
      widget.onAcceptedDelivery();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _acceptingDeliveryId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeliveryProvider provider = context.watch<DeliveryProvider>();

    if (!widget.isOnline) {
      return const EmptyStateWidget(
        title: 'Você está offline',
        subtitle: 'Ative o modo online para receber entregas.',
        icon: Icons.wifi_off_outlined,
      );
    }

    if (provider.isLoading && provider.availableDeliveries.isEmpty) {
      return const LoadingWidget(message: 'Buscando entregas disponíveis...');
    }

    if (provider.error != null && provider.availableDeliveries.isEmpty) {
      return _ErrorView(message: provider.error!, onRetry: _refreshAvailable);
    }

    if (provider.availableDeliveries.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshAvailable,
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 120),
            const EmptyStateWidget(
              title: 'Nenhuma entrega disponível no momento',
              subtitle: 'Atualize a tela novamente em instantes.',
              icon: Icons.delivery_dining_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshAvailable,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.availableDeliveries.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final delivery = provider.availableDeliveries[index];

          return DeliveryCard(
            delivery: delivery,
            driverLatitude: _driverPosition?.latitude,
            driverLongitude: _driverPosition?.longitude,
            isLoading: _acceptingDeliveryId == delivery.id,
            onAccept: () => _accept(delivery.id),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
