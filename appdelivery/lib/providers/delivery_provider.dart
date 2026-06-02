import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';
import '../models/delivery_model.dart';
import '../models/order_model.dart';

class DeliveryProvider extends ChangeNotifier {
  DeliveryProvider();

  List<DeliveryModel> _availableDeliveries = <DeliveryModel>[];
  DeliveryModel? _activeDelivery;
  List<DeliveryModel> _deliveryHistory = <DeliveryModel>[];
  bool _isLoading = false;
  String? _error;

  List<DeliveryModel> get availableDeliveries =>
      List<DeliveryModel>.unmodifiable(_availableDeliveries);
  DeliveryModel? get activeDelivery => _activeDelivery;
  List<DeliveryModel> get deliveryHistory =>
      List<DeliveryModel>.unmodifiable(_deliveryHistory);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Dio get _dio => ApiService.instance.dio;

  Future<void> loadAvailable() async {
    _setLoading(true);
    _error = null;

    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.get(
        ApiConstants.deliveriesAvailable,
        options: options,
      );
      final List<dynamic> list = ApiService.listFromResponse(response.data);

      final List<DeliveryModel> deliveries = list
          .map(
            (dynamic item) =>
                DeliveryModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      _availableDeliveries = deliveries;
    } catch (error) {
      _error = _readableError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptDelivery(int id) async {
    _setLoading(true);
    _error = null;

    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.post(
        ApiConstants.deliveryAccept(id),
        options: options,
      );
      final Map<String, dynamic> data = ApiService.dataFromResponse(
        response.data,
      );
      final DeliveryModel delivery = DeliveryModel.fromJson(data);
      _activeDelivery = await _withOrder(delivery);
      _availableDeliveries.removeWhere((item) => item.id == id);
    } catch (error) {
      _error = _readableError(error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    _setLoading(true);
    _error = null;

    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.patch(
        ApiConstants.deliveryStatus(id),
        data: <String, dynamic>{'status': status},
        options: options,
      );

      final Map<String, dynamic> data = ApiService.dataFromResponse(
        response.data,
      );

      final DeliveryModel updated = await _withOrder(
        DeliveryModel.fromJson(data),
      );

      if (updated.status == 'delivered' || updated.status == 'failed') {
        _activeDelivery = null;
      } else {
        _activeDelivery = updated;
      }

      await loadHistory();
    } catch (error) {
      _error = _readableError(error);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateLocation(int id, double lat, double lng) async {
    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.patch(
        ApiConstants.deliveryLocation(id),
        data: <String, dynamic>{
          'driver_latitude': lat,
          'driver_longitude': lng,
        },
        options: options,
      );

      final Map<String, dynamic> data = ApiService.dataFromResponse(
        response.data,
      );

      final DeliveryModel updated = DeliveryModel.fromJson(data);

      if (_activeDelivery != null && _activeDelivery!.id == id) {
        _activeDelivery = _activeDelivery!.copyWith(
          driverLatitude: updated.driverLatitude,
          driverLongitude: updated.driverLongitude,
        );
        notifyListeners();
      }
    } catch (_) {
      // Ignored to prevent UI blocking while tracking driver location.
    }
  }

  Future<void> loadHistory() async {
    _setLoading(true);
    _error = null;

    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.get(
        ApiConstants.deliveriesMy,
        options: options,
      );
      final List<dynamic> list = ApiService.listFromResponse(response.data);

      final List<DeliveryModel> deliveries = await Future.wait(
        list.map((dynamic item) async {
          final DeliveryModel delivery = DeliveryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          return _withOrder(delivery);
        }),
      );

      _deliveryHistory = deliveries;

      final DeliveryModel? active = deliveries
          .cast<DeliveryModel?>()
          .firstWhere(
            (DeliveryModel? delivery) =>
                delivery != null &&
                (delivery.status == 'accepted' ||
                    delivery.status == 'picked_up'),
            orElse: () => null,
          );

      _activeDelivery = active;
    } catch (error) {
      _error = _readableError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshActiveDelivery() async {
    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.get(
        ApiConstants.deliveriesMy,
        options: options,
      );
      final List<dynamic> list = ApiService.listFromResponse(response.data);

      final List<DeliveryModel> deliveries = await Future.wait(
        list.map((dynamic item) async {
          final DeliveryModel delivery = DeliveryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          return _withOrder(delivery);
        }),
      );

      final DeliveryModel? active = deliveries
          .cast<DeliveryModel?>()
          .firstWhere(
            (DeliveryModel? delivery) =>
                delivery != null &&
                (delivery.status == 'accepted' ||
                    delivery.status == 'picked_up'),
            orElse: () => null,
          );

      _activeDelivery = active;
      _deliveryHistory = deliveries;
      notifyListeners();
    } catch (_) {
      // Background refresh errors are ignored.
    }
  }

  Future<DeliveryModel> _withOrder(DeliveryModel delivery) async {
    if (delivery.status == 'waiting') {
      return delivery;
    }

    try {
      final Options options = await ApiService.authenticatedOptions();
      final Response response = await _dio.get(
        ApiConstants.orderDetail(delivery.orderId),
        options: options,
      );
      final Map<String, dynamic> data = ApiService.dataFromResponse(
        response.data,
      );
      final OrderModel order = OrderModel.fromJson(data);
      return delivery.copyWith(order: order);
    } on DioException {
      return delivery;
    }
  }

  void clearState() {
    _availableDeliveries = <DeliveryModel>[];
    _activeDelivery = null;
    _deliveryHistory = <DeliveryModel>[];
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _readableError(Object error) {
    if (error is DioException) {
      if (error.error is ApiException) {
        return (error.error as ApiException).message;
      }
      return error.message ?? 'Falha ao comunicar com o servidor.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}
