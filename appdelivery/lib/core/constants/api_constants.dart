class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = 'http://localhost:8001';

  static const String login = '/api/users/login/';
  static const String logout = '/api/users/logout/';
  static const String me = '/api/users/me/';

  static const String deliveriesAvailable = '/api/deliveries/available/';
  static const String deliveriesMy = '/api/deliveries/my-deliveries/';

  static String deliveryAccept(int id) => '/api/deliveries/$id/accept/';
  static String deliveryStatus(int id) => '/api/deliveries/$id/status/';
  static String deliveryLocation(int id) => '/api/deliveries/$id/location/';

  static String orderDetail(int id) => '/api/orders/$id/';
}
