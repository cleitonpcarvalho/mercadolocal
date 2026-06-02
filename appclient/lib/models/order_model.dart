import 'delivery_model.dart';

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] ?? 0) as int,
      productId: (json['product_id'] ?? 0) as int,
      productName: (json['product_name'] ?? '') as String,
      quantity: (json['quantity'] ?? 0) as int,
      unitPrice: _toDouble(json['unit_price']) ?? 0,
      subtotal: _toDouble(json['subtotal']) ?? 0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.storeName,
    required this.status,
    required this.total,
    this.subtotal,
    this.deliveryFee,
    this.commissionFee,
    this.paymentMethod,
    this.paymentStatus,
    this.deliveryAddress,
    this.createdAt,
    this.items = const <OrderItemModel>[],
    this.delivery,
  });

  final int id;
  final String storeName;
  final String status;
  final double total;
  final double? subtotal;
  final double? deliveryFee;
  final double? commissionFee;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? deliveryAddress;
  final DateTime? createdAt;
  final List<OrderItemModel> items;
  final DeliveryModel? delivery;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>?) ?? <dynamic>[];

    return OrderModel(
      id: (json['id'] ?? 0) as int,
      storeName: (json['store_name'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      total: _toDouble(json['total']) ?? 0,
      subtotal: _toDouble(json['subtotal']),
      deliveryFee: _toDouble(json['delivery_fee']),
      commissionFee: _toDouble(json['commission_fee']),
      paymentMethod: json['payment_method'] as String?,
      paymentStatus: json['payment_status'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      createdAt: _toDate(json['created_at']),
      items: itemsJson
          .map(
            (item) =>
                OrderItemModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      delivery: json['delivery'] is Map
          ? DeliveryModel.fromJson(
              Map<String, dynamic>.from(json['delivery'] as Map),
            )
          : null,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
