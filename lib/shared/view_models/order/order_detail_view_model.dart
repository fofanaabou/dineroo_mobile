import 'dart:async';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_details.dart';
import 'package:dineroo_mobile/shared/models/domain/order_event.dart';
import 'package:dineroo_mobile/shared/models/dto/order_dto.dart';
import 'package:dineroo_mobile/shared/realtime/handlers/customer_order_realtime_service.dart';
import 'package:dineroo_mobile/shared/repositories/order_details_repository.dart';
import 'package:dineroo_mobile/shared/services/order/shared_order_service.dart';
import 'package:flutter/material.dart';

class OrderDetailViewModel extends ChangeNotifier {
  final SharedOrderService _sharedOrderService;
  final OrderDetailsRepository _orderDetailsRepository;
  final CustomerOrderRealtimeService _customerRealtimeService;
  final ApiContext? _apiContext;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Order? _order;
  Order? get order => _order;

  OrderDetails? _orderDetails;
  OrderDetails? get orderDetails => _orderDetails;

  void Function(Order)? _onOrderFetched;
  void Function(OrderEvent)? _onRealtimeEvent;

  StreamSubscription<OrderEvent>? _subscription;

  OrderDetailViewModel({
    required SharedOrderService sharedOrderService,
    required OrderDetailsRepository orderDetailsRepository,
    CustomerOrderRealtimeService? customerRealtimeService,
    ApiContext? apiContext,
  }) : _sharedOrderService = sharedOrderService,
       _orderDetailsRepository = orderDetailsRepository,
       _customerRealtimeService =
           customerRealtimeService ?? CustomerOrderRealtimeService(),
       _apiContext = apiContext;

  Future<void> init(dynamic orderId) async {
    await fetchOrderById(orderId);
  }

  Future<void> initWithRealtime(
    dynamic orderId,
    String customerId, {
    void Function(Order)? onOrderFetched,
    void Function(OrderEvent)? onRealtimeEvent,
  }) async {
    _onOrderFetched = onOrderFetched;
    _onRealtimeEvent = onRealtimeEvent;

    await fetchOrderById(orderId);
    await _subscribeToRealtime(orderId.toString(), customerId: customerId);
  }

  Future<void> fetchOrderById(dynamic orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _sharedOrderService.fetchOrderById(orderId, context: _apiContext),
        _orderDetailsRepository.fetchOrderDetails(orderId.toString()),
      ]);

      _order =
          OrderDto.fromJson(results[0] as Map<String, dynamic>).toDomain();
      _orderDetails = results[1] as OrderDetails?;
      _onOrderFetched?.call(_order!);
    } catch (e, stack) {
      logger.e('Failed to fetch order detail', error: e, stackTrace: stack);
      _error = 'Échec du chargement de la commande';
      _order = null;
      _orderDetails = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _subscribeToRealtime(
    String orderId, {
    required String customerId,
  }) async {
    await _customerRealtimeService.subscribeToOrderStatus(
      customerId: customerId,
      orderId: orderId,
    );

    await _subscription?.cancel();
    _subscription = _customerRealtimeService.stream
        .where((event) => event.orderId == orderId)
        .listen(_handleRealtimeEvent);
  }

  Future<void> _handleRealtimeEvent(OrderEvent event) async {
    logger.i(
      '[RT][OrderDetail] Updating order ${event.orderId} with status ${event.status}',
    );

    if (_order != null) {
      _order = _order!.copyWith(status: event.statusEnum);
      notifyListeners();
    }

    _onRealtimeEvent?.call(event);

    try {
      final results = await Future.wait([
        _sharedOrderService.fetchOrderById(event.orderId, context: _apiContext),
        _orderDetailsRepository.fetchOrderDetails(event.orderId),
      ]);

      final freshOrder =
          OrderDto.fromJson(results[0] as Map<String, dynamic>).toDomain();
      final freshOrderDetails = results[1] as OrderDetails?;

      _order = freshOrder;
      _orderDetails = freshOrderDetails;
      _onOrderFetched?.call(freshOrder);
      notifyListeners();
    } catch (e, stack) {
      logger.e(
        '[RT][OrderDetail] Could not refresh order after realtime event',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
