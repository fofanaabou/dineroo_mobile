import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/common/helpers/order_helper.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';

class Order {
  final dynamic id;
  final String shortId;
  final String? name;
  final String restaurantId;
  final String restaurantName;
  final double totalPrice;
  final double? serviceFee;
  final double? deliveryFee;
  final OrderDeliveryContact deliveryContact;
  final OrderStatus status;
  final DateTime createdDate;
  final DateTime lastModifiedDate;
  final List<OrderItem> items;
  final String? comment;
  final String? customerId;
  final DateTime? statusDate;

  Order({
    required this.id,
    required this.shortId,
    this.name,
    required this.restaurantId,
    required this.restaurantName,
    required this.totalPrice,
    this.serviceFee,
    this.deliveryFee,
    required this.deliveryContact,
    required this.status,
    required this.createdDate,
    required this.lastModifiedDate,
    required this.items,
    this.comment,
    this.customerId,
    this.statusDate,
  });

  String get displayName =>
      name?.trim().isNotEmpty == true ? name! : 'Commande #$shortId';
  bool get hasComment => (comment ?? '').trim().isNotEmpty;
  String get deliveryAddress => deliveryContact.fullAddress;

  Order copyWith({
    dynamic id,
    String? shortId,
    String? name,
    String? restaurantId,
    String? restaurantName,
    double? totalPrice,
    double? serviceFee,
    double? deliveryFee,
    OrderDeliveryContact? deliveryContact,
    OrderStatus? status,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    List<OrderItem>? items,
    String? comment,
    String? customerId,
    DateTime? statusDate,
  }) {
    return Order(
      id: id ?? this.id,
      shortId: shortId ?? this.shortId,
      name: name ?? this.name,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      totalPrice: totalPrice ?? this.totalPrice,
      serviceFee: serviceFee ?? this.serviceFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryContact: deliveryContact ?? this.deliveryContact,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      items: items ?? this.items,
      comment: comment ?? this.comment,
      customerId: customerId ?? this.customerId,
      statusDate: statusDate ?? this.statusDate,
    );
  }
}

class OrderItem {
  final int id;
  final dynamic orderId;
  final String? menuId;
  final String? productId;
  final String imageUrl;
  final int quantity;
  final double price;
  final String? name;
  final String restaurantId;
  final String restaurantName;

  OrderItem({
    required this.id,
    required this.orderId,
    this.menuId,
    this.productId,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    this.name,
    required this.restaurantId,
    required this.restaurantName,
  });

  bool get isMenu => menuId != null;
  bool get isProduct => productId != null;

  String get displayName => getOrderItemDisplayName(id, name);

  OrderItem copyWith({
    int? id,
    dynamic orderId,
    String? menuId,
    String? productId,
    String? imageUrl,
    int? quantity,
    double? price,
    String? name,
    String? restaurantId,
    String? restaurantName,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuId: menuId ?? this.menuId,
      productId: productId ?? this.productId,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      name: name ?? this.name,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }
}
