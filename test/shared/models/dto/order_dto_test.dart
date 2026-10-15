import 'package:dineroo_mobile/shared/enums/order_status.dart';
import 'package:dineroo_mobile/shared/models/dto/order_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderDto', () {
    test('parses JSON with delivery contact and order items', () {
      final dto = OrderDto.fromJson(_json());

      expect(dto.id, 'order-1');
      expect(dto.shortId, 'A123');
      expect(dto.totalPrice, 35000.0);
      expect(dto.serviceFee, 1000.0);
      expect(dto.deliveryFee, 5000.0);
      expect(dto.deliveryContact.phoneNumber, '620000000');
      expect(dto.items.single.id, 42);
      expect(dto.items.single.name, 'Burger');
      expect(dto.statusDate, '2026-01-01T10:13:00Z');
    });

    test('uses safe defaults for optional fields', () {
      final dto = OrderDto.fromJson({'id': 'order-1'});

      expect(dto.shortId, '');
      expect(dto.restaurantId, '');
      expect(dto.restaurantName, '');
      expect(dto.totalPrice, 0.0);
      expect(dto.serviceFee, isNull);
      expect(dto.deliveryFee, isNull);
      expect(dto.deliveryContact.address, '');
      expect(dto.items, isEmpty);
    });

    test('converts to domain order', () {
      final order = OrderDto.fromJson(_json()).toDomain();

      expect(order.id, 'order-1');
      expect(order.displayName, 'Déjeuner');
      expect(order.status, OrderStatus.accepted);
      expect(order.createdDate, DateTime.parse('2026-01-01T10:00:00Z'));
      expect(order.statusDate, DateTime.parse('2026-01-01T10:13:00Z'));
      expect(order.deliveryAddress, 'Rue 1, Kaloum, Conakry');
      expect(order.items.single.restaurantId, 'restaurant-1');
      expect(order.items.single.restaurantName, 'Chez Fatou');
      expect(order.items.single.isProduct, isTrue);
    });
  });

  group('OrderDeliveryContactDto', () {
    test('parses JSON and converts to domain contact', () {
      final contact = OrderDeliveryContactDto.fromJson({
        'phoneNumber': 620000000,
        'address': 'Rue 1',
        'district': 'Kaloum',
        'commune': 'Conakry',
        'instructions': 'Devant la banque',
        'firstName': 'Aminata',
        'lastName': 'Diallo',
      }).toDomain();

      expect(contact.phoneNumber, '620000000');
      expect(contact.fullAddress, 'Rue 1, Kaloum, Conakry');
      expect(contact.displayName, 'Aminata Diallo');
    });
  });

  group('OrderItemDto', () {
    test('parses itemName first and converts to domain item', () {
      final item = OrderItemDto.fromJson({
        'id': '7',
        'orderId': 12,
        'menuId': 'menu-1',
        'quantity': '2',
        'price': '15000.5',
        'itemName': 'Menu soir',
      }).toDomain(restaurantId: 'restaurant-1', restaurantName: 'Chez Fatou');

      expect(item.id, 7);
      expect(item.orderId, '12');
      expect(item.isMenu, isTrue);
      expect(item.quantity, 2);
      expect(item.price, 15000.5);
      expect(item.displayName, 'Menu soir');
    });
  });
}

Map<String, dynamic> _json() => {
  'id': 'order-1',
  'shortId': 'A123',
  'name': 'Déjeuner',
  'restaurantId': 'restaurant-1',
  'restaurantName': 'Chez Fatou',
  'totalPrice': '35000',
  'serviceFee': 1000,
  'deliveryFee': 5000,
  'status': 'ACCEPTED',
  'createdDate': '2026-01-01T10:00:00Z',
  'lastModifiedDate': '2026-01-01T10:05:00Z',
  'statusDate': '2026-01-01T10:13:00Z',
  'comment': 'Sans piment',
  'customerId': 'customer-1',
  'deliveryContact': {
    'phoneNumber': '620000000',
    'address': 'Rue 1',
    'district': 'Kaloum',
    'commune': 'Conakry',
    'firstName': 'Aminata',
    'lastName': 'Diallo',
  },
  'orderItems': [
    {
      'id': 42,
      'orderId': 'order-1',
      'productId': 'product-1',
      'imageUrl': 'https://example.com/product.jpg',
      'quantity': 2,
      'price': 15000,
      'name': 'Burger',
    },
  ],
};
