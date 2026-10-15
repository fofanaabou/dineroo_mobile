import 'package:dineroo_mobile/manager/repositories/manager_restaurant_repository.dart';
import 'package:dineroo_mobile/manager/services/manager_restaurant_service.dart';
import 'package:dineroo_mobile/manager/view_models/restaurant/manager_restaurant_view_model.dart';
import 'package:dineroo_mobile/shared/common/helpers/api_context_helper.dart';
import 'package:dineroo_mobile/shared/enums/suspension_reason.dart';
import 'package:dineroo_mobile/shared/exceptions/restaurant_suspended_exception.dart';
import 'package:dineroo_mobile/shared/models/domain/opening_hours.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManagerRestaurantViewModel', () {
    test('fetches opening hours and toggles loading state', () async {
      final service = _FakeManagerRestaurantService();
      final viewModel = _viewModel(service);
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

      await viewModel.loadRestaurantState('restaurant-1');

      expect(service.fetchedRestaurantIds, ['restaurant-1']);
      expect(service.fetchContexts, [ApiContext.restaurant]);
      expect(viewModel.error, isNull);
      expect(viewModel.openingHours, hasLength(1));
      expect(viewModel.openingHours.single.day, 'MONDAY');
      expect(viewModel.openingHours.single.timeRanges.single.start, '09:00');
      expect(loadingStates, [true, false]);
    });

    test('stores the service error message when fetch fails', () async {
      final service = _FakeManagerRestaurantService()
        ..fetchError = Exception('offline');
      final viewModel = _viewModel(service);

      await viewModel.loadRestaurantState('restaurant-1');

      expect(viewModel.openingHours, isEmpty);
      expect(viewModel.error, 'offline');
      expect(viewModel.isLoading, isFalse);
    });

    test('adds and replaces day opening hours locally', () {
      final viewModel = _viewModel(_FakeManagerRestaurantService());
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setDayOpeningHours('MONDAY', [
        TimeRange(start: '09:00', end: '18:00'),
      ]);
      viewModel.setDayOpeningHours('TUESDAY', [
        TimeRange(start: '10:00', end: '16:00'),
      ]);
      viewModel.setDayOpeningHours('MONDAY', [
        TimeRange(start: '08:00', end: '12:00'),
      ]);

      expect(viewModel.openingHours, hasLength(2));
      expect(
        viewModel.openingHours
            .firstWhere((hours) => hours.day == 'MONDAY')
            .timeRanges
            .single
            .start,
        '08:00',
      );
      expect(notifications, 3);
    });

    test('saves opening hours payload and toggles saving state', () async {
      final service = _FakeManagerRestaurantService();
      final viewModel = _viewModel(service)
        ..setDayOpeningHours('MONDAY', [
          TimeRange(start: '09:00', end: '12:00'),
          TimeRange(start: '14:00', end: '18:00'),
        ])
        ..setDayOpeningHours('TUESDAY', const []);
      final savingStates = <bool>[];
      viewModel.addListener(() => savingStates.add(viewModel.isSaving));

      await viewModel.saveOpeningHours('restaurant-1');

      expect(service.updatedRestaurantIds, ['restaurant-1']);
      expect(service.updatedOpeningHours.single, [
        {
          'day': 'MONDAY',
          'timeRanges': [
            {'start': '09:00', 'end': '12:00'},
            {'start': '14:00', 'end': '18:00'},
          ],
        },
        {'day': 'TUESDAY', 'timeRanges': <Map<String, String>>[]},
      ]);
      expect(viewModel.error, isNull);
      expect(savingStates, [true, false]);
    });

    test('stores save errors without throwing', () async {
      final service = _FakeManagerRestaurantService()
        ..updateError = Exception('patch failed');
      final viewModel = _viewModel(service)
        ..setDayOpeningHours('MONDAY', [
          TimeRange(start: '09:00', end: '18:00'),
        ]);

      await viewModel.saveOpeningHours('restaurant-1');

      expect(viewModel.error, contains('patch failed'));
      expect(viewModel.isSaving, isFalse);
    });

    test('exposes the suspension returned by the RESTAURANT context', () async {
      final service = _FakeManagerRestaurantService()
        ..suspension = {
          'reason': 'UNRESPONSIVE_TO_ORDERS',
          'suspendedAt': '2026-08-18T10:15:30Z',
        };
      final viewModel = _viewModel(service);

      await viewModel.loadRestaurantState('restaurant-1');

      expect(viewModel.isSuspended, isTrue);
      expect(
        viewModel.suspension!.reason,
        SuspensionReason.unresponsiveToOrders,
      );
      expect(viewModel.openingHours, hasLength(1));
    });

    test('is not suspended when the payload carries no suspension', () async {
      final viewModel = _viewModel(_FakeManagerRestaurantService());

      await viewModel.loadRestaurantState('restaurant-1');

      expect(viewModel.suspension, isNull);
      expect(viewModel.isSuspended, isFalse);
    });

    test(
      'surfaces a suspension refusal as the banner message and reloads state',
      () async {
        final service = _FakeManagerRestaurantService()
          ..updateError = const RestaurantSuspendedException()
          ..suspension = {
            'reason': 'CONTRACT_BREACH',
            'suspendedAt': '2026-08-18T10:15:30Z',
          };
        final viewModel = _viewModel(service)
          ..setDayOpeningHours('MONDAY', [
            TimeRange(start: '09:00', end: '18:00'),
          ]);

        await viewModel.saveOpeningHours('restaurant-1');

        expect(viewModel.error, RestaurantSuspendedException.message);
        expect(viewModel.error, isNot(contains('Exception')));
        expect(service.fetchedRestaurantIds, ['restaurant-1']);
        expect(viewModel.isSuspended, isTrue);
        expect(viewModel.isSaving, isFalse);
      },
    );

    test(
      'keeps the suspension message when the post-refusal reload fails',
      () async {
        final service = _FakeManagerRestaurantService()
          ..updateError = const RestaurantSuspendedException()
          ..fetchError = Exception('timeout');
        final viewModel = _viewModel(service)
          ..setDayOpeningHours('MONDAY', [
            TimeRange(start: '09:00', end: '18:00'),
          ]);
        final observedErrors = <String?>[];
        viewModel.addListener(() => observedErrors.add(viewModel.error));

        await viewModel.saveOpeningHours('restaurant-1');

        expect(viewModel.error, RestaurantSuspendedException.message);
        expect(service.fetchedRestaurantIds, ['restaurant-1']);
        expect(viewModel.isSaving, isFalse);
        expect(
          observedErrors,
          isNot(contains(contains('timeout'))),
          reason: 'the reload failure must never be shown to the manager',
        );
      },
    );

    test('currentRestaurantId returns null without CurrentUserViewModel', () {
      final viewModel = _viewModel(_FakeManagerRestaurantService());
      expect(viewModel.currentRestaurantId, isNull);
    });

    test(
      'loadRestaurantState with no id stops early when no currentRestaurantId',
      () async {
        final service = _FakeManagerRestaurantService();
        final viewModel = _viewModel(service);
        final loadingStates = <bool>[];
        viewModel.addListener(() => loadingStates.add(viewModel.isLoading));

        await viewModel.loadRestaurantState();

        expect(service.fetchedRestaurantIds, isEmpty);
        expect(loadingStates.last, false);
      },
    );
  });
}

ManagerRestaurantViewModel _viewModel(_FakeManagerRestaurantService service) {
  return ManagerRestaurantViewModel(
    ManagerRestaurantRepository(service: service),
  );
}

class _FakeManagerRestaurantService extends ManagerRestaurantService {
  final fetchedRestaurantIds = <String>[];
  final fetchContexts = <ApiContext>[];
  final updatedRestaurantIds = <String>[];
  final updatedOpeningHours = <List<Map<String, dynamic>>>[];

  Object? fetchError;
  Object? updateError;
  Map<String, dynamic>? suspension;

  @override
  Future<Map<String, dynamic>> fetchRestaurant(
    String restaurantId, {
    required ApiContext context,
  }) async {
    fetchedRestaurantIds.add(restaurantId);
    fetchContexts.add(context);

    final error = fetchError;
    if (error != null) throw error;

    return {
      'id': restaurantId,
      'name': 'Chez Mariam',
      'imageUrl': 'https://cdn.test/restaurant.png',
      'description': 'Cuisine guinéenne',
      'address': 'Kaloum',
      'phone': '620000000',
      'openingHours': [
        {
          'day': 'MONDAY',
          'timeRanges': [
            {'start': '09:00', 'end': '18:00'},
          ],
        },
      ],
      if (suspension != null) 'suspension': suspension,
    };
  }

  @override
  Future<void> updateOpeningHours(
    String restaurantId,
    List<Map<String, dynamic>> openingHours,
  ) async {
    updatedRestaurantIds.add(restaurantId);
    updatedOpeningHours.add(openingHours);

    final error = updateError;
    if (error != null) throw error;
  }
}
