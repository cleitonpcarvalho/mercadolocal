import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../models/delivery_model.dart';
import '../common/app_button.dart';
import 'delivery_status_badge.dart';

class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    required this.delivery,
    required this.onAccept,
    super.key,
    this.isLoading = false,
    this.driverLatitude,
    this.driverLongitude,
  });

  final DeliveryModel delivery;
  final VoidCallback onAccept;
  final bool isLoading;
  final double? driverLatitude;
  final double? driverLongitude;

  @override
  Widget build(BuildContext context) {
    final double? distanceKm = _distanceKm();

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
          const SizedBox(height: 8),
          Text(
            'Retirada: ${_pickupAddressLabel()}',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray700),
          ),
          const SizedBox(height: 2),
          Text(
            'Entrega: ${delivery.resolvedDeliveryAddress}',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray700),
          ),
          if ((delivery.orderNotes ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'Observações: ${delivery.orderNotes}',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray700),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: <Widget>[
              Text(
                'Taxa: ${Formatters.currency(delivery.resolvedDeliveryFee)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Distância: ${distanceKm == null ? '-' : '${distanceKm.toStringAsFixed(1)} km'}',
                style: AppTextStyles.caption,
              ),
              Text(
                'Aguardando: ${Formatters.relativeTime(delivery.createdAt)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Aceitar entrega',
            isLoading: isLoading,
            onPressed: onAccept,
          ),
        ],
      ),
    );
  }

  double? _distanceKm() {
    if (driverLatitude == null || driverLongitude == null) {
      return null;
    }
    if (delivery.pickupLatitude == null || delivery.pickupLongitude == null) {
      return null;
    }

    final Distance distance = const Distance();
    final double meters = distance.as(
      LengthUnit.Meter,
      LatLng(driverLatitude!, driverLongitude!),
      LatLng(delivery.pickupLatitude!, delivery.pickupLongitude!),
    );

    return meters / 1000;
  }

  String _pickupAddressLabel() {
    if (delivery.pickupLatitude == null || delivery.pickupLongitude == null) {
      return 'Local da loja';
    }

    return 'Lat ${delivery.pickupLatitude!.toStringAsFixed(5)}, Lng ${delivery.pickupLongitude!.toStringAsFixed(5)}';
  }
}
