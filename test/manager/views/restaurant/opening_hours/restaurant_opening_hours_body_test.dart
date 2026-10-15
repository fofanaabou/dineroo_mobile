import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/manager/views/home/manager_suspension_banner.dart';
import 'package:dineroo_mobile/manager/views/restaurant/opening_hours/restaurant_opening_hours_body.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _restaurantId = 'restaurant-1';

void main() {
  testWidgets('lets an active restaurant save its opening hours', (
    tester,
  ) async {
    await _pumpBody(tester, suspension: null);

    expect(find.byType(ManagerSuspensionBanner), findsNothing);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('locks the save action and says why when suspended', (
    tester,
  ) async {
    await _pumpBody(
      tester,
      suspension: const {
        'reason': 'SERVICE_QUALITY',
        'suspendedAt': '2026-08-18T10:15:30Z',
      },
    );

    expect(find.byType(ManagerSuspensionBanner), findsOneWidget);
    expect(find.text('Restaurant suspendu'), findsOneWidget);
    expect(find.text('Réclamations qualité / hygiène'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
  });
}

ElevatedButton _saveButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Enregistrer'),
      matching: find.byType(ElevatedButton),
    ),
  );
}

Future<void> _pumpBody(
  WidgetTester tester, {
  required Map<String, dynamic>? suspension,
}) async {
  final viewModel = ManagerRestaurantViewModel(
    ManagerRestaurantRepository(
      service: _FakeManagerRestaurantService(suspension: suspension),
    ),
  );
  await viewModel.loadRestaurantState(_restaurantId);

  await tester.pumpWidget(
    ChangeNotifierProvider<ManagerRestaurantViewModel>.value(
      value: viewModel,
      child: const MaterialApp(
        home: Scaffold(
          body: RestaurantOpeningHoursBody(restaurantId: _restaurantId),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _FakeManagerRestaurantService extends ManagerRestaurantService {
  _FakeManagerRestaurantService({this.suspension});

  final Map<String, dynamic>? suspension;

  @override
  Future<Map<String, dynamic>> fetchRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    return {
      'id': restaurantId,
      'name': 'Chez Mariam',
      'imageUrl': 'https://cdn.test/restaurant.png',
      'openingHours': const <Map<String, dynamic>>[],
      if (suspension != null) 'suspension': suspension,
    };
  }
}
