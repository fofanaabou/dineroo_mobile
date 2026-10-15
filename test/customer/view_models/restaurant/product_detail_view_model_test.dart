import 'package:dineroo_mobile/customer/services/restaurant/product_service.dart';
import 'package:dineroo_mobile/customer/view_models/restaurant/product_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductDetailViewModel', () {
    test(
      'fetchProduct maps catalogue payload and initializes empty selections',
      () async {
        final viewModel = ProductDetailViewModel(
          productService: _FakeProductService(
            response: {
              'id': 'product-1',
              'name': 'Burger',
              'price': 8000,
              'imageUrl': 'https://img/burger.jpg',
              'description': 'Burger maison',
              'productType': 'burger',
              'restaurantId': 'restaurant-1',
              'restaurantName': 'Chez Fatou',
              'available': true,
              'choiceGroups': [
                {
                  'id': 'sauce',
                  'name': 'Sauce',
                  'required': true,
                  'minSelections': 1,
                  'maxSelections': 2,
                  'items': [
                    {
                      'id': 'piment',
                      'productId': 'piment',
                      'productName': 'Piment',
                      'additionalPrice': 250,
                    },
                  ],
                },
              ],
            },
          ),
        );

        await viewModel.fetchProduct('restaurant-1', 'product-1');

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
        expect(viewModel.product!.name, 'Burger');
        expect(viewModel.product!.choiceGroups.single.name, 'Sauce');
        expect(viewModel.selectedCount('sauce'), 0);
        viewModel.dispose();
      },
    );

    test('enforces required and max selection rules', () async {
      final viewModel = ProductDetailViewModel(
        productService: _FakeProductService(response: _productJson()),
      );
      await viewModel.fetchProduct('restaurant-1', 'product-1');

      expect(viewModel.validateSelections(), isFalse);
      expect(viewModel.selectionErrorGroupId, 'side');
      expect(viewModel.selectionErrorText, 'Veuillez sélectionner 1 option');

      viewModel.incrementSelection('side', 'riz');
      expect(viewModel.selectionErrorGroupId, isNull);
      expect(viewModel.validateSelections(), isTrue);

      viewModel.incrementSelection('side', 'frites');
      expect(viewModel.selectedCount('side'), 1);

      viewModel.dispose();
    });

    test(
      'calculates total and builds selected product choices with quantities',
      () async {
        final viewModel = ProductDetailViewModel(
          productService: _FakeProductService(response: _productJson(max: 3)),
        );
        await viewModel.fetchProduct('restaurant-1', 'product-1');

        viewModel.incrementSelection('side', 'riz');
        viewModel.incrementSelection('side', 'riz');
        viewModel.incrementSelection('side', 'frites');
        viewModel.decrementSelection('side', 'riz');

        expect(viewModel.itemQuantity('side', 'riz'), 1);
        expect(viewModel.calculateTotalPrice(), 9250);

        final choices = viewModel.buildChoices();
        expect(
          choices.map((choice) => choice.itemName),
          containsAll(['Riz', 'Frites']),
        );
        expect(
          choices.singleWhere((choice) => choice.itemId == 'riz').quantity,
          1,
        );
        expect(
          choices
              .singleWhere((choice) => choice.itemId == 'frites')
              .additionalPrice,
          1000,
        );

        viewModel.dispose();
      },
    );

    test('captures service errors without leaving loading stuck', () async {
      final viewModel = ProductDetailViewModel(
        productService: _FakeProductService(error: Exception('boom')),
      );

      await viewModel.fetchProduct('restaurant-1', 'product-1');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.product, isNull);
      expect(viewModel.error, contains('boom'));
      viewModel.dispose();
    });
  });
}

Map<String, dynamic> _productJson({int max = 1}) => {
  'id': 'product-1',
  'name': 'Burger',
  'price': 8000,
  'imageUrl': '',
  'description': '',
  'productType': 'product',
  'restaurantId': 'restaurant-1',
  'restaurantName': 'Chez Fatou',
  'available': true,
  'choiceGroups': [
    {
      'id': 'side',
      'name': 'Accompagnement',
      'required': true,
      'minSelections': 1,
      'maxSelections': max,
      'items': [
        {
          'id': 'riz',
          'productId': 'riz',
          'productName': 'Riz',
          'additionalPrice': 250,
        },
        {
          'id': 'frites',
          'productId': 'frites',
          'productName': 'Frites',
          'additionalPrice': 1000,
        },
      ],
    },
  ],
};

class _FakeProductService extends ProductService {
  final Map<String, dynamic>? response;
  final Object? error;

  _FakeProductService({this.response, this.error});

  @override
  Future<Map<String, dynamic>> fetchProductDetail(
    String restaurantId,
    String productId,
  ) async {
    final failure = error;
    if (failure != null) throw failure;
    return response!;
  }
}
