class StoreCategoryModel {
  const StoreCategoryModel({required this.id, required this.name, this.icon});

  final int id;
  final String name;
  final String? icon;

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) {
    return StoreCategoryModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      icon: json['icon'] as String?,
    );
  }
}

class StoreModel {
  const StoreModel({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.phone,
    this.city,
    this.state,
    this.address,
    this.latitude,
    this.longitude,
    this.categories = const <StoreCategoryModel>[],
    this.averageRating,
  });

  final int id;
  final String name;
  final String? description;
  final String? logo;
  final String? phone;
  final String? city;
  final String? state;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<StoreCategoryModel> categories;
  final double? averageRating;

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final categoriesJson =
        (json['categories'] as List<dynamic>?) ?? <dynamic>[];

    return StoreModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      address: json['address'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      averageRating: _toDouble(json['average_rating']),
      categories: categoriesJson
          .map(
            (item) => StoreCategoryModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
