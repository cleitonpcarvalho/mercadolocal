import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/delivery_model.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/delivery/delivery_status_badge.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({
    required this.isOnline,
    required this.onCompletedDelivery,
    super.key,
  });

  final bool isOnline;
  final VoidCallback onCompletedDelivery;

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final LocationService _locationService = const LocationService();
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _locationSyncTimer;

  LatLng? _driverPosition;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant ActiveDeliveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _startLocationSync();
      } else {
        _stopLocationSync();
      }
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stopLocationSync();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final DeliveryProvider provider = context.read<DeliveryProvider>();
    await provider.refreshActiveDelivery();

    _positionSubscription?.cancel();
    _positionSubscription = _locationService.startLocationStream().listen((
      Position position,
    ) {
      if (!mounted) return;

      setState(() {
        _driverPosition = LatLng(position.latitude, position.longitude);
      });
    });

    if (widget.isOnline) {
      _startLocationSync();
    }
  }

  void _startLocationSync() {
    _locationSyncTimer?.cancel();

    _locationSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!widget.isOnline) return;

      final DeliveryProvider provider = context.read<DeliveryProvider>();
      final DeliveryModel? active = provider.activeDelivery;

      if (active == null || _driverPosition == null) return;

      await provider.updateLocation(
        active.id,
        _driverPosition!.latitude,
        _driverPosition!.longitude,
      );
    });
  }

  void _stopLocationSync() {
    _locationSyncTimer?.cancel();
    _locationSyncTimer = null;
  }

  Future<void> _advanceStatus(DeliveryModel delivery) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    final DeliveryProvider provider = context.read<DeliveryProvider>();

    try {
      if (delivery.status == 'accepted') {
        await provider.updateStatus(delivery.id, 'picked_up');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Retirada confirmada.'),
          ),
        );
      } else if (delivery.status == 'picked_up') {
        await provider.updateStatus(delivery.id, 'delivered');

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Entrega finalizada'),
              content: const Text('Entrega confirmada com sucesso.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;
        widget.onCompletedDelivery();
      }
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
          _isUpdatingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeliveryProvider provider = context.watch<DeliveryProvider>();
    final DeliveryModel? delivery = provider.activeDelivery;

    if (provider.isLoading && delivery == null) {
      return const LoadingWidget(message: 'Buscando entrega ativa...');
    }

    if (provider.error != null && delivery == null) {
      return _ErrorView(
        message: provider.error!,
        onRetry: () => context.read<DeliveryProvider>().refreshActiveDelivery(),
      );
    }

    if (delivery == null) {
      return const EmptyStateWidget(
        title: 'Nenhuma entrega ativa',
        subtitle: 'Aceite uma nova entrega para iniciar a rota.',
        icon: Icons.route_outlined,
      );
    }

    final LatLng pickupPoint = LatLng(
      delivery.pickupLatitude ?? -3.7319,
      delivery.pickupLongitude ?? -38.5267,
    );
    final LatLng deliveryPoint = LatLng(
      delivery.deliveryLatitude ?? pickupPoint.latitude,
      delivery.deliveryLongitude ?? pickupPoint.longitude,
    );
    final LatLng rawDriverPoint =
        _driverPosition ??
        (delivery.driverLatitude != null && delivery.driverLongitude != null
            ? LatLng(delivery.driverLatitude!, delivery.driverLongitude!)
            : pickupPoint);
    final LatLng routeCenter = _midpoint(pickupPoint, deliveryPoint);
    final bool driverNearRoute = _isDriverNearRoute(
      driverPoint: rawDriverPoint,
      pickupPoint: pickupPoint,
      deliveryPoint: deliveryPoint,
    );
    final LatLng mapCenter = driverNearRoute ? rawDriverPoint : routeCenter;
    final LatLng nextTargetPoint = delivery.status == 'accepted'
        ? pickupPoint
        : deliveryPoint;

    return Column(
      children: <Widget>[
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mercadolocal.appdelivery',
              ),
              PolylineLayer(
                polylines: <Polyline>[
                  Polyline(
                    points: <LatLng>[pickupPoint, deliveryPoint],
                    strokeWidth: 3,
                    color: AppColors.gray500.withAlpha(140),
                  ),
                  Polyline(
                    points: <LatLng>[rawDriverPoint, nextTargetPoint],
                    strokeWidth: 4,
                    color: AppColors.primary.withAlpha(160),
                  ),
                ],
              ),
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point: pickupPoint,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.mapPickupPin,
                      size: 36,
                    ),
                  ),
                  Marker(
                    point: deliveryPoint,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.mapDeliveryPin,
                      size: 38,
                    ),
                  ),
                  Marker(
                    point: rawDriverPoint,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.delivery_dining,
                      color: AppColors.mapDriverPin,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: _StatusActionCard(
            delivery: delivery,
            isLoading: _isUpdatingStatus,
            onPressed: () => _advanceStatus(delivery),
          ),
        ),
      ],
    );
  }

  LatLng _midpoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  bool _isDriverNearRoute({
    required LatLng driverPoint,
    required LatLng pickupPoint,
    required LatLng deliveryPoint,
  }) {
    final double distanceToPickupKm = _distance.as(
      LengthUnit.Kilometer,
      driverPoint,
      pickupPoint,
    );
    final double distanceToDeliveryKm = _distance.as(
      LengthUnit.Kilometer,
      driverPoint,
      deliveryPoint,
    );
    return distanceToPickupKm <= 50 || distanceToDeliveryKm <= 50;
  }
}

class _StatusActionCard extends StatelessWidget {
  const _StatusActionCard({
    required this.delivery,
    required this.onPressed,
    required this.isLoading,
  });

  final DeliveryModel delivery;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool canConfirmPickup = delivery.status == 'accepted';
    final bool canConfirmDelivery = delivery.status == 'picked_up';

    final String buttonLabel = canConfirmPickup
        ? 'Confirmar retirada'
        : canConfirmDelivery
        ? 'Confirmar entrega'
        : 'Aguardando próxima etapa';

    final bool buttonEnabled = canConfirmPickup || canConfirmDelivery;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.gray900.withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  delivery.storeName ?? 'Loja',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.gray900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DeliveryStatusBadge(status: delivery.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cliente: ${delivery.customerName ?? '-'}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            'Endereço de entrega: ${delivery.resolvedDeliveryAddress}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            'Itens: ${delivery.resolvedItemsCount} | Total: ${Formatters.currency(delivery.resolvedOrderTotal)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 2),
          Text(
            'Taxa: ${Formatters.currency(delivery.resolvedDeliveryFee)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((delivery.orderNotes ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'Observações: ${delivery.orderNotes}',
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: 10),
          AppButton(
            label: buttonLabel,
            isLoading: isLoading,
            onPressed: buttonEnabled ? onPressed : null,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
