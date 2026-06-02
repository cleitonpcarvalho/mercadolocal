import 'package:dio/dio.dart';

import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../models/user_model.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class MarketService {
  const MarketService();

  Dio get _dio => ApiService.instance.dio;

  List<ProductModel> _parseProducts(dynamic body) {
    final list = ApiService.listFromResponse(body);
    return list
        .map(
          (item) =>
              ProductModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  List<StoreModel> _parseStores(dynamic body) {
    final list = ApiService.listFromResponse(body);
    return list
        .map(
          (item) => StoreModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  List<OrderModel> _parseOrders(dynamic body) {
    final list = ApiService.listFromResponse(body);
    return list
        .map(
          (item) => OrderModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: {'is_featured': true},
    );
    return _parseProducts(response.data);
  }

  Future<List<ProductModel>> searchProducts({
    String? search,
    String? condition,
    int? category,
    int? store,
    double? minPrice,
    double? maxPrice,
  }) async {
    final Map<String, dynamic> queryParameters =
        <String, dynamic>{
          'search': search,
          'condition': condition,
          'category': category,
          'store': store,
          'min_price': minPrice,
          'max_price': maxPrice,
        }..removeWhere(
          (String key, dynamic value) =>
              value == null || (value is String && value.isEmpty),
        );

    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: queryParameters,
    );

    return _parseProducts(response.data);
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await _dio.get('${ApiConstants.products}$id/');
    final data = ApiService.dataFromResponse(response.data);
    return ProductModel.fromJson(data);
  }

  Future<List<StoreModel>> getStores({String? city, String? state}) async {
    final response = await _dio.get(
      ApiConstants.stores,
      queryParameters: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
      },
    );

    return _parseStores(response.data);
  }

  Future<StoreModel> getStoreById(int id) async {
    final response = await _dio.get('${ApiConstants.stores}$id/');
    final data = ApiService.dataFromResponse(response.data);
    return StoreModel.fromJson(data);
  }

  Future<List<StoreCategoryModel>> getStoreCategories() async {
    final response = await _dio.get(ApiConstants.storeCategories);
    final list = ApiService.listFromResponse(response.data);
    return list
        .map(
          (item) => StoreCategoryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getProductCategories() async {
    final response = await _dio.get(ApiConstants.productCategories);
    final list = ApiService.listFromResponse(response.data);
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> getActiveBannerAds() async {
    final response = await _dio.get(
      ApiConstants.adsActive,
      queryParameters: {'ad_type': 'banner'},
    );

    final list = ApiService.listFromResponse(response.data);
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> registerAdClick(int id) async {
    await _dio.post('/api/ads/$id/click/');
  }

  Future<OrderModel> createOrder(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.orders, data: payload);
    final data = ApiService.dataFromResponse(response.data);
    return OrderModel.fromJson(data);
  }

  Future<List<OrderModel>> getOrders() async {
    final response = await _dio.get(ApiConstants.orders);
    return _parseOrders(response.data);
  }

  Future<List<OrderModel>> getOrdersByStatus(String status) async {
    final response = await _dio.get(
      ApiConstants.orders,
      queryParameters: {'status': status},
    );
    return _parseOrders(response.data);
  }

  Future<OrderModel> getOrderById(int id) async {
    final response = await _dio.get('${ApiConstants.orders}$id/');
    final data = ApiService.dataFromResponse(response.data);
    return OrderModel.fromJson(data);
  }

  Future<DeliveryModel> getDeliveryById(int id) async {
    final response = await _dio.get('${ApiConstants.deliveries}$id/');
    final data = ApiService.dataFromResponse(response.data);
    return DeliveryModel.fromJson(data);
  }

  Future<DeliveryModel> getDeliveryLocation(int id) async {
    // Location updates are available in the delivery detail payload.
    return getDeliveryById(id);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> payload) async {
    final response = await _dio.patch(ApiConstants.me, data: payload);
    final data = ApiService.dataFromResponse(response.data);
    return UserModel.fromJson(data);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/users/change-password/',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<StoreModel?> getMyStore() async {
    try {
      final response = await _dio.get('/api/stores/my-store/');
      final data = ApiService.dataFromResponse(response.data);
      if (data.isEmpty) return null;
      return StoreModel.fromJson(data);
    } on DioException {
      return null;
    }
  }

  Future<StoreModel> createStore(FormData formData) async {
    final response = await _dio.post(
      ApiConstants.stores,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = ApiService.dataFromResponse(response.data);
    return StoreModel.fromJson(data);
  }

  Future<StoreModel> updateStore(int id, FormData formData) async {
    final response = await _dio.patch(
      '${ApiConstants.stores}$id/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = ApiService.dataFromResponse(response.data);
    return StoreModel.fromJson(data);
  }

  Future<List<ProductModel>> getMyProducts() async {
    final response = await _dio.get('/api/products/my-products/');
    return _parseProducts(response.data);
  }

  Future<ProductModel> createProduct(FormData formData) async {
    final response = await _dio.post(
      ApiConstants.products,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = ApiService.dataFromResponse(response.data);
    return ProductModel.fromJson(data);
  }

  Future<ProductModel> updateProduct(int id, FormData formData) async {
    final response = await _dio.patch(
      '${ApiConstants.products}$id/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = ApiService.dataFromResponse(response.data);
    return ProductModel.fromJson(data);
  }

  Future<void> archiveProduct(int id) async {
    await _dio.delete('${ApiConstants.products}$id/');
  }

  Future<void> updateOrderStatus({
    required int id,
    required String status,
  }) async {
    await _dio.patch('/api/orders/$id/status/', data: {'status': status});
  }

  Future<List<Map<String, dynamic>>> getMyAds() async {
    final response = await _dio.get('/api/ads/my-ads/');
    final list = ApiService.listFromResponse(response.data);
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> createAd(FormData formData) async {
    final response = await _dio.post(
      '/api/ads/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ApiService.dataFromResponse(response.data);
  }
}
