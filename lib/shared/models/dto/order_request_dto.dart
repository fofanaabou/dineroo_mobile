import 'package:dineroo_mobile/customer/models/domain/cart_group.dart';
import 'package:dineroo_mobile/customer/models/domain/product_choice_item.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/models/extensions/product_extensions.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/phone_helper.dart';

class OrderRequestDto {
  final double totalPrice;
  final double? serviceFee;
  final double? deliveryFee;
  final Map<String, dynamic> deliveryContact;
  final List<Map<String, dynamic>> orderItems;
  final String status;
  final String comment;
  final String restaurantId;
  final String customerId;

  OrderRequestDto({
    required this.totalPrice,
    this.serviceFee,
    this.deliveryFee,
    required this.deliveryContact,
    required this.orderItems,
    required this.status,
    required this.comment,
    required this.restaurantId,
    required this.customerId,
  });

  factory OrderRequestDto.fromCart({
    required CartGroup cart,
    required User currentUser,
    required CartViewModel cartVM,
    required String comment,
  }) {
    final estimatedTotal = cartVM.totalFor(cart);
    final estimatedServiceFee = cartVM.serviceFeeFor(cart);
    final estimatedDeliveryFee = cartVM.deliveryFeeFor(cart);

    if (estimatedTotal == null) {
      throw StateError('Order estimation is unavailable');
    }

    return OrderRequestDto(
      totalPrice: estimatedTotal,
      serviceFee: estimatedServiceFee,
      deliveryFee: estimatedDeliveryFee,
      deliveryContact: {
        "phoneNumber": formatPhoneGuinea(cartVM.deliveryPhoneNumber ?? ''),
        "address": cartVM.deliveryAddress,
        "district": cartVM.deliveryDistrict,
        "commune": cartVM.deliveryCommune,
        "instructions": cartVM.deliveryInstructions,
        "firstName": cartVM.deliveryFirstName,
        "lastName": cartVM.deliveryLastName,
      },
      orderItems: cart.items
          .map(
            (item) => {
              if (item.isConfiguredItem) ...{
                'productId': item.isConfiguredProduct ? item.product.id : null,
                'menuId': item.isConfiguredMenu ? item.product.id : null,
                'itemName': item.product.name,
                'imageUrl': item.product.imageUrl,
                'quantity': item.quantity,
                'price': item.unitPrice,
                'selectedMenuItems': item.selectedMenuItems!
                    .map(
                      (sel) => {
                        'groupId': sel.groupId,
                        'groupName': sel.groupName,
                        'menuItemId': sel.menuItemId,
                        'productId': sel.productId,
                        'productName': sel.productName,
                        'additionalPrice': sel.additionalPrice,
                        if (sel.productChoices != null)
                          'productChoices':
                              ProductChoiceItem.listToJson(sel.productChoices!),
                      },
                    )
                    .toList(),
              } else ...{
                'productId': item.product.isProduct ? item.product.id : null,
                'menuId': item.product.isMenu ? item.product.id : null,
                'itemName': item.product.name,
                'imageUrl': item.product.imageUrl,
                'quantity': item.quantity,
                'price': item.product.price,
              },
            },
          )
          .toList(),
      status: 'PENDING',
      comment: comment,
      restaurantId: cart.restaurantId,
      customerId: currentUser.id,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalPrice': totalPrice,
    'serviceFee': serviceFee,
    'deliveryFee': deliveryFee,
    'deliveryContact': deliveryContact,
    'orderItems': orderItems,
    'status': status,
    'comment': comment,
    'restaurantId': restaurantId,
    'customerId': customerId,
  };
}
