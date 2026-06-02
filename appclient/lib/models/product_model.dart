class ProductStoreSummary {
  const ProductStoreSummary({
    required this.id,
    required this.name,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;

  factory ProductStoreSummary.fromJson(Map<String, dynamic> json) {
    return ProductStoreSummary(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      city: json['city'] as String?,
      address: json['address'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class ProductImageModel {
  const ProductImageModel({
    required this.id,
    required this.image,
    this.order = 0,
  });

  final int id;
  final String image;
  final int order;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: (json['id'] ?? 0) as int,
      image: (json['image'] ?? '') as String,
      order: (json['order'] ?? 0) as int,
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.condition,
    this.description,
    this.stock,
    this.weightKg,
    this.isAvailable = true,
    this.isFeatured = false,
    this.pickupOnly = false,
    this.store,
    this.categoryName,
    this.firstImage,
    this.images = const <ProductImageModel>[],
  });

  final int id;
  final String name;
  final double price;
  final String condition;
  final String? description;
  final int? stock;
  final double? weightKg;
  final bool isAvailable;
  final bool isFeatured;
  final bool pickupOnly;
  final ProductStoreSummary? store;
  final String? categoryName;
  final String? firstImage;
  final List<ProductImageModel> images;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imagesJson = (json['images'] as List<dynamic>?) ?? <dynamic>[];

    return ProductModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      price: _toDouble(json['price']) ?? 0,
      condition: (json['condition'] ?? 'new') as String,
      description: json['description'] as String?,
      stock: json['stock'] as int?,
      weightKg: _toDouble(json['weight_kg']),
      isAvailable: (json['is_available'] ?? true) as bool,
      isFeatured: (json['is_featured'] ?? false) as bool,
      pickupOnly: (json['pickup_only'] ?? false) as bool,
      store: json['store'] is Map
          ? ProductStoreSummary.fromJson(
              Map<String, dynamic>.from(json['store'] as Map),
            )
          : null,
      categoryName:
          json['category_name'] as String? ??
          (json['category'] is Map
              ? (json['category'] as Map)['name']?.toString()
              : null),
      firstImage: json['first_image'] as String?,
      images: imagesJson
          .map(
            (item) => ProductImageModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  String? get displayImage {
    if (images.isNotEmpty) return images.first.image;
    return firstImage;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
