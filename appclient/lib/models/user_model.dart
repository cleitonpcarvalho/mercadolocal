class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.isVerified = false,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;
  final String? city;
  final String? state;
  final double? latitude;
  final double? longitude;
  final bool isVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'customer') as String,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isVerified: (json['is_verified'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'city': city,
      'state': state,
      'latitude': latitude,
      'longitude': longitude,
      'is_verified': isVerified,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      city: city ?? this.city,
      state: state ?? this.state,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
