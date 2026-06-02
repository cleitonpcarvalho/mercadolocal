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
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;
  final String? city;
  final String? state;

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
    );
  }
}
