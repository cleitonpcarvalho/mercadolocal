import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/market_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/order/order_status_badge.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({required this.orderId, super.key});

  final int orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MarketService _marketService = const MarketService();
  final Distance _distance = const Distance();

  Timer? _pollTimer;

  bool _isLoading = true;
  bool _isPolling = false;
  String? _error;

  OrderModel? _order;
  DeliveryModel? _delivery;
  List<LatLng> _driverTrail = <LatLng>[];

  static const List<String> _timeline = <String>[
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'in_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _poll();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final OrderModel order = await _marketService.getOrderById(
        widget.orderId,
      );
      DeliveryModel? delivery = order.delivery;

      if (order.status == 'in_delivery' && delivery != null) {
        delivery = await _marketService.getDeliveryLocation(delivery.id);
      }

      if (!mounted) return;

      setState(() {
        _order = order;
        _delivery = delivery;
        _syncDriverTrail(order: order, delivery: delivery);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _poll() async {
    if (_isPolling) return;
    _isPolling = true;

    try {
      final OrderModel order = await _marketService.getOrderById(
        widget.orderId,
      );
      DeliveryModel? delivery = order.delivery;

      if (order.status == 'in_delivery' && delivery != null) {
        delivery = await _marketService.getDeliveryLocation(delivery.id);
      }

      if (!mounted) return;

      setState(() {
        _order = order;
        _delivery = delivery;
        _syncDriverTrail(order: order, delivery: delivery);
      });
    } catch (_) {
      // Polling errors are ignored to keep the screen responsive.
    } finally {
      _isPolling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go('/orders');
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        title: Text('Rastreio do pedido #${widget.orderId}'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray900,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _load);
    }

    final OrderModel? order = _order;
    if (order == null) {
      return const EmptyStateWidget(
        title: 'Pedido não encontrado',
        subtitle: 'Verifique se o pedido ainda está disponível.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.storeName,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.dateTime(order.createdAt),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Formatters.currency(order.total),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTimeline(order.status),
        const SizedBox(height: 12),
        _buildMapCard(order),
        const SizedBox(height: 12),
        _buildItemsCard(order),
        const SizedBox(height: 12),
        _buildDriverInfoCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final String normalizedStatus = _normalizeStatus(currentStatus);
    final int currentIndex = _timeline.indexOf(normalizedStatus);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Status do pedido',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          ..._timeline.asMap().entries.map((entry) {
            final int index = entry.key;
            final String status = entry.value;
            final bool active = currentIndex >= index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.gray300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _labelStatus(status),
                    style: AppTextStyles.body.copyWith(
                      color: active ? AppColors.gray900 : AppColors.gray500,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (normalizedStatus == 'cancelled')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Pedido cancelado',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapCard(OrderModel order) {
    final DeliveryModel? delivery = _delivery ?? order.delivery;

    if (delivery == null) {
      return const EmptyStateWidget(
        title: 'Entrega ainda não atribuída',
        subtitle: 'Assim que um entregador aceitar, o mapa será atualizado.',
      );
    }

    if (!_isValidCoordinate(
          delivery.pickupLatitude,
          delivery.pickupLongitude,
        ) ||
        !_isValidCoordinate(
          delivery.deliveryLatitude,
          delivery.deliveryLongitude,
        )) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Mapa da entrega',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Não foi possível carregar as coordenadas de entrega deste pedido.',
            ),
            const SizedBox(height: 4),
            Text(
              'Endereço: ${order.deliveryAddress ?? '-'}',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray700),
            ),
          ],
        ),
      );
    }

    final LatLng pickup = LatLng(
      delivery.pickupLatitude!,
      delivery.pickupLongitude!,
    );
    final LatLng destination = LatLng(
      delivery.deliveryLatitude!,
      delivery.deliveryLongitude!,
    );

    final LatLng routeCenter = _midpoint(pickup, destination);
    final LatLng? driverPoint =
        delivery.driverLatitude != null && delivery.driverLongitude != null
        ? LatLng(delivery.driverLatitude!, delivery.driverLongitude!)
        : null;
    final LatLng mapCenter =
        driverPoint != null &&
            _isDriverNearRoute(
              driverPoint: driverPoint,
              pickupPoint: pickup,
              deliveryPoint: destination,
            )
        ? driverPoint
        : routeCenter;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Mapa da entrega',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mercadolocal.appclient',
                  ),
                  PolylineLayer(
                    polylines: <Polyline>[
                      Polyline(
                        points: <LatLng>[pickup, destination],
                        strokeWidth: 3,
                        color: AppColors.gray500.withAlpha(140),
                      ),
                      if (_driverTrail.length > 1)
                        Polyline(
                          points: _driverTrail,
                          strokeWidth: 3,
                          color: AppColors.info.withAlpha(170),
                        ),
                      if (driverPoint != null)
                        Polyline(
                          points: <LatLng>[driverPoint, destination],
                          strokeWidth: 4,
                          color: AppColors.primary.withAlpha(170),
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: pickup,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.storefront_outlined,
                          size: 34,
                          color: AppColors.info,
                        ),
                      ),
                      Marker(
                        point: destination,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.location_on,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      if (driverPoint != null)
                        Marker(
                          point: driverPoint,
                          width: 42,
                          height: 42,
                          child: const Icon(
                            Icons.delivery_dining,
                            size: 34,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.status == 'in_delivery'
                ? 'Atualização automática a cada 5 segundos.'
                : 'A entrega ainda não está em rota.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(
            'Entrega: ${order.deliveryAddress ?? '-'}',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray700),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(OrderModel order) {
    if (order.items.isEmpty) {
      return const EmptyStateWidget(
        title: 'Sem itens para exibir',
        subtitle: 'Os itens do pedido não foram retornados pela API.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Itens do pedido',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (OrderItemModel item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productName}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.currency(item.subtotal),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    final DeliveryModel? delivery = _delivery;

    if (delivery == null || delivery.driverId == null) {
      return const EmptyStateWidget(
        title: 'Entregador ainda não atribuído',
        subtitle: 'Quando houver um motorista, os dados aparecerão aqui.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Informações do entregador',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.gray100,
                child: const Icon(Icons.person, color: AppColors.gray700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Motorista #${delivery.driverId}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Avaliação: -', style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (delivery.estimatedMinutes != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${delivery.estimatedMinutes} min',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _labelStatus(String value) {
    switch (_normalizeStatus(value)) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'preparing':
        return 'Em preparação';
      case 'ready':
        return 'Aguardando entregador';
      case 'in_delivery':
        return 'Em entrega';
      case 'delivered':
        return 'Entregue';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Status';
    }
  }

  String _normalizeStatus(String value) {
    return value.toString().trim().toLowerCase().replaceAll(' ', '_');
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

  bool _isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  void _syncDriverTrail({
    required OrderModel order,
    required DeliveryModel? delivery,
  }) {
    if (order.status != 'in_delivery' ||
        delivery == null ||
        !_isValidCoordinate(
          delivery.driverLatitude,
          delivery.driverLongitude,
        ) ||
        !_isValidCoordinate(
          delivery.pickupLatitude,
          delivery.pickupLongitude,
        ) ||
        !_isValidCoordinate(
          delivery.deliveryLatitude,
          delivery.deliveryLongitude,
        )) {
      _driverTrail = <LatLng>[];
      return;
    }

    final LatLng driverPoint = LatLng(
      delivery.driverLatitude!,
      delivery.driverLongitude!,
    );
    final LatLng pickupPoint = LatLng(
      delivery.pickupLatitude!,
      delivery.pickupLongitude!,
    );
    final LatLng destinationPoint = LatLng(
      delivery.deliveryLatitude!,
      delivery.deliveryLongitude!,
    );

    if (!_isDriverNearRoute(
      driverPoint: driverPoint,
      pickupPoint: pickupPoint,
      deliveryPoint: destinationPoint,
    )) {
      return;
    }

    if (_driverTrail.isEmpty) {
      _driverTrail = <LatLng>[driverPoint];
      return;
    }

    final LatLng lastPoint = _driverTrail.last;
    final double movedMeters = _distance.as(
      LengthUnit.Meter,
      lastPoint,
      driverPoint,
    );

    if (movedMeters < 10) return;

    _driverTrail = <LatLng>[..._driverTrail, driverPoint];
    if (_driverTrail.length > 240) {
      _driverTrail = _driverTrail.sublist(_driverTrail.length - 240);
    }
  }
}
