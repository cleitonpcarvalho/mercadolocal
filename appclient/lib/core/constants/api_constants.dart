class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'http://localhost:8001';

  static const String login = '/api/users/login/';
  static const String register = '/api/users/register/';
  static const String refreshToken = '/api/users/token/refresh/';
  static const String logout = '/api/users/logout/';
  static const String me = '/api/users/me/';

  static const String stores = '/api/stores/';
  static const String storeCategories = '/api/stores/categories/';

  static const String products = '/api/products/';
  static const String productCategories = '/api/products/categories/';

  static const String adsActive = '/api/ads/active/';

  static const String orders = '/api/orders/';
  static const String deliveries = '/api/deliveries/';
}
