import 'order_model.dart';

class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.status,
    this.orderStatus,
    this.storeId,
    this.storeName,
    this.storeCity,
    this.customerId,
    this.customerName,
    this.deliveryAddress,
    this.orderNotes,
    this.deliveryFee,
    this.orderTotal,
    this.driverId,
    this.vehicleType,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.estimatedMinutes,
    this.createdAt,
    this.deliveredAt,
    this.order,
  });

  final int id;
  final int orderId;
  final String status;
  final String? orderStatus;
  final int? storeId;
  final String? storeName;
  final String? storeCity;
  final int? customerId;
  final String? customerName;
  final String? deliveryAddress;
  final String? orderNotes;
  final double? deliveryFee;
  final double? orderTotal;
  final int? driverId;
  final String? vehicleType;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? driverLatitude;
  final double? driverLongitude;
  final int? estimatedMinutes;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final OrderModel? order;

  bool get isActive => status == 'accepted' || status == 'picked_up';
  String get resolvedDeliveryAddress =>
      order?.deliveryAddress ?? deliveryAddress ?? '-';
  double get resolvedDeliveryFee => order?.deliveryFee ?? deliveryFee ?? 0;
  double get resolvedOrderTotal => order?.total ?? orderTotal ?? 0;
  int get resolvedItemsCount => order?.itemsCount ?? 0;

  DeliveryModel copyWith({
    int? id,
    int? orderId,
    String? status,
    String? orderStatus,
    int? storeId,
    String? storeName,
    String? storeCity,
    int? customerId,
    String? customerName,
    String? deliveryAddress,
    String? orderNotes,
    double? deliveryFee,
    double? orderTotal,
    int? driverId,
    String? vehicleType,
    double? pickupLatitude,
    double? pickupLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? driverLatitude,
    double? driverLongitude,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? deliveredAt,
    OrderModel? order,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      orderStatus: orderStatus ?? this.orderStatus,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      storeCity: storeCity ?? this.storeCity,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      orderNotes: orderNotes ?? this.orderNotes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      orderTotal: orderTotal ?? this.orderTotal,
      driverId: driverId ?? this.driverId,
      vehicleType: vehicleType ?? this.vehicleType,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      order: order ?? this.order,
    );
  }

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: (json['id'] ?? 0) as int,
      orderId: (json['order_id'] ?? 0) as int,
      status: (json['status'] ?? 'waiting') as String,
      orderStatus: json['order_status'] as String?,
      storeId: json['store_id'] as int?,
      storeName: json['store_name'] as String?,
      storeCity: json['store_city'] as String?,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      orderNotes: json['order_notes'] as String?,
      deliveryFee: _toDouble(json['delivery_fee']),
      orderTotal: _toDouble(json['order_total']),
      driverId: json['driver'] as int?,
      vehicleType: json['vehicle_type'] as String?,
      pickupLatitude: _toDouble(json['pickup_latitude']),
      pickupLongitude: _toDouble(json['pickup_longitude']),
      deliveryLatitude: _toDouble(json['delivery_latitude']),
      deliveryLongitude: _toDouble(json['delivery_longitude']),
      driverLatitude: _toDouble(json['driver_latitude']),
      driverLongitude: _toDouble(json['driver_longitude']),
      estimatedMinutes: json['estimated_minutes'] as int?,
      createdAt: _toDateTime(json['created_at']),
      deliveredAt: _toDateTime(json['delivered_at']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
