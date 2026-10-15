import 'dart:io';

import 'package:dineroo_mobile/customer/models/domain/cart_item.dart';
import 'package:dineroo_mobile/customer/models/domain/delivery_address.dart';
import 'package:dineroo_mobile/customer/models/domain/product.dart';
import 'package:dineroo_mobile/customer/models/domain/user.dart';
import 'package:dineroo_mobile/customer/view_models/cart/cart_view_model.dart';
import 'package:dineroo_mobile/customer/views/cart/delivery_contact_form_sheet.dart';
import 'package:dineroo_mobile/shared/view_models/user/current_user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory hiveDir;
  late CartViewModel cartViewModel;
  late CurrentUserViewModel currentUserViewModel;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('delivery_form_test_');
    Hive.init(hiveDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CartItemAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DeliveryAddressAdapter());
    }
    await Hive.openBox<DeliveryAddress>('deliveryAddressBox');
  });

  setUp(() async {
    await Hive.box<DeliveryAddress>('deliveryAddressBox').clear();
    cartViewModel = CartViewModel();
    currentUserViewModel = CurrentUserViewModel();
  });

  tearDown(() async {
    cartViewModel.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  tearDownAll(() async {
    // Avoid closing Hive explicitly here: flutter_tester can hang while a
    // widget-owned box is finalizing async writes. The test process is isolated.
  });

  group('DeliveryContactFormSheet', () {
    testWidgets('prefills user data and saves delivery contact', (
      tester,
    ) async {
      currentUserViewModel.setUser(
        User(
          id: 'user-1',
          firstName: 'Aminata',
          lastName: 'Diallo',
          phoneNumber: '620000000',
          role: 'CUSTOMER',
          isTemporaryPin: false,
        ),
      );

      await tester.pumpWidget(
        _SheetHarness(cartViewModel, currentUserViewModel),
      );

      expect(find.text('Informations de livraison'), findsOneWidget);
      expect(_fieldAt(tester, 0).controller?.text, 'Aminata');
      expect(_fieldAt(tester, 1).controller?.text, 'Diallo');
      expect(_fieldAt(tester, 2).controller?.text, '620 00 00 00');

      await tester.enterText(find.byType(TextFormField).at(3), 'Rue 12');
      await tester.enterText(find.byType(TextFormField).at(4), 'Kipé');
      await tester.enterText(find.byType(TextFormField).at(5), 'Ratoma');
      await tester.enterText(find.byType(TextFormField).at(6), 'Portail bleu');

      await tester.tap(find.text('Enregistrer'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(cartViewModel.deliveryDisplayName, 'Aminata Diallo');
      expect(cartViewModel.deliveryPhoneNumber, '620 00 00 00');
      expect(cartViewModel.deliveryAddress, 'Rue 12');
      expect(cartViewModel.deliveryDistrict, 'Kipé');
      expect(cartViewModel.deliveryCommune, 'Ratoma');
      expect(cartViewModel.deliveryInstructions, 'Portail bleu');
      expect(cartViewModel.isDeliveryConfirmedForCurrentOrder, isTrue);
    });
  });
}

TextFormField _fieldAt(WidgetTester tester, int index) =>
    tester.widget<TextFormField>(find.byType(TextFormField).at(index));

class _SheetHarness extends StatelessWidget {
  final CartViewModel cartViewModel;
  final CurrentUserViewModel currentUserViewModel;

  const _SheetHarness(this.cartViewModel, this.currentUserViewModel);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartViewModel>.value(value: cartViewModel),
        ChangeNotifierProvider<CurrentUserViewModel>.value(
          value: currentUserViewModel,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 720, child: DeliveryContactFormSheet()),
        ),
      ),
    );
  }
}
