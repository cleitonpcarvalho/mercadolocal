class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.status,
    this.orderId,
    this.driverId,
    this.vehicleType,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.estimatedMinutes,
  });

  final int id;
  final String status;
  final int? orderId;
  final int? driverId;
  final String? vehicleType;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? driverLatitude;
  final double? driverLongitude;
  final int? estimatedMinutes;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: (json['id'] ?? 0) as int,
      status: (json['status'] ?? 'waiting') as String,
      orderId: json['order_id'] as int? ?? json['order'] as int?,
      driverId: json['driver'] as int?,
      vehicleType: json['vehicle_type'] as String?,
      pickupLatitude: _toDouble(json['pickup_latitude']),
      pickupLongitude: _toDouble(json['pickup_longitude']),
      deliveryLatitude: _toDouble(json['delivery_latitude']),
      deliveryLongitude: _toDouble(json['delivery_longitude']),
      driverLatitude: _toDouble(json['driver_latitude']),
      driverLongitude: _toDouble(json['driver_longitude']),
      estimatedMinutes: json['estimated_minutes'] as int?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
