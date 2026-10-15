import 'package:dineroo_mobile/shared/models/domain/order.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/common/utils/parser_utils.dart';

class OrderDto {
  final String id;
  final String shortId;
  final String? name;
  final String restaurantId;
  final String restaurantName;
  final double totalPrice;
  final double? serviceFee;
  final double? deliveryFee;
  final OrderDeliveryContactDto deliveryContact;
  final String status;
  final String createdDate;
  final String lastModifiedDate;
  final List<OrderItemDto> items;
  final String? comment;
  final String? customerId;
  final String? statusDate;

  OrderDto({
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

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'].toString(),
      shortId: json['shortId']?.toString() ?? '',
      name: json['name']?.toString(),
      restaurantId: json['restaurantId']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? '',
      totalPrice: parseToDouble(json['totalPrice']),
      serviceFee: json['serviceFee'] != null
          ? parseToDouble(json['serviceFee'])
          : null,
      deliveryFee: json['deliveryFee'] != null
          ? parseToDouble(json['deliveryFee'])
          : null,
      deliveryContact: OrderDeliveryContactDto.fromJson(
        (json['deliveryContact'] as Map<String, dynamic>?) ?? const {},
      ),
      status: json['status']?.toString() ?? '',
      createdDate: json['createdDate']?.toString() ?? '',
      lastModifiedDate: json['lastModifiedDate']?.toString() ?? '',
      comment: json['comment']?.toString(),
      customerId: json['customerId']?.toString(),
      items: (json['orderItems'] as List? ?? [])
          .map((e) => OrderItemDto.fromJson(e))
          .toList(),
      statusDate: json['statusDate']?.toString(),
    );
  }

  Order toDomain() {
    return Order(
      id: id,
      shortId: shortId,
      name: name,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      totalPrice: totalPrice,
      serviceFee: serviceFee,
      deliveryFee: deliveryFee,
      deliveryContact: deliveryContact.toDomain(),
      status: OrderStatus.fromString(status),
      createdDate: DateTime.tryParse(createdDate) ?? DateTime.now(),
      lastModifiedDate: DateTime.tryParse(lastModifiedDate) ?? DateTime.now(),
      items: items
          .map(
            (i) => i.toDomain(
              restaurantId: restaurantId,
              restaurantName: restaurantName,
            ),
          )
          .toList(),
      comment: comment,
      customerId: customerId,
      statusDate: statusDate != null
          ? DateTime.tryParse(statusDate!)
          : null,
    );
  }
}

class OrderDeliveryContactDto {
  final String phoneNumber;
  final String address;
  final String? district;
  final String? commune;
  final String? instructions;
  final String? firstName;
  final String? lastName;

  OrderDeliveryContactDto({
    required this.phoneNumber,
    required this.address,
    this.district,
    this.commune,
    this.instructions,
    this.firstName,
    this.lastName,
  });

  factory OrderDeliveryContactDto.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryContactDto(
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString(),
      commune: json['commune']?.toString(),
      instructions: json['instructions']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
    );
  }

  OrderDeliveryContact toDomain() {
    return OrderDeliveryContact(
      phoneNumber: phoneNumber,
      address: address,
      district: district,
      commune: commune,
      instructions: instructions,
      firstName: firstName,
      lastName: lastName,
    );
  }
}

class OrderItemDto {
  final int id;
  final String orderId;
  final String? menuId;
  final String? productId;
  final String imageUrl;
  final int quantity;
  final double price;
  final String? name;

  OrderItemDto({
    required this.id,
    required this.orderId,
    this.menuId,
    this.productId,
    required this.imageUrl,
    required this.quantity,
    required this.price,
    this.name,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      id: parseToInt(json['id']),
      orderId: json['orderId'].toString(),
      menuId: json['menuId']?.toString(),
      productId: json['productId']?.toString(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      quantity: parseToInt(json['quantity']),
      price: parseToDouble(json['price']),
      name: json['itemName']?.toString() ?? json['name']?.toString(),
    );
  }

  OrderItem toDomain({
    required String restaurantId,
    required String restaurantName,
  }) {
    return OrderItem(
      id: id,
      orderId: orderId,
      menuId: menuId,
      productId: productId,
      imageUrl: imageUrl,
      quantity: quantity,
      price: price,
      name: name,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );
  }
}
