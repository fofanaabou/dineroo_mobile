import 'package:dineroo_mobile/shared/common/utils/map_query_builder.dart';
import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapQueryBuilder', () {
    test('builds default client query when contact is missing', () {
      expect(MapQueryBuilder.buildClientQuery(null), 'Conakry, Guinée');
    });

    test('builds client query from district, landmark hints, and commune', () {
      final contact = OrderDeliveryContact(
        address: '  Adresse  ',
        district: '  Kipé  ',
        commune: 'Ratoma',
        instructions: 'Instructions: près de la pharmacie, deuxième porte',
        phoneNumber: '620000000',
      );

      expect(
        MapQueryBuilder.buildClientQuery(contact),
        'Kipé, près de la pharmacie, deuxième porte, Ratoma, Conakry, Guinée',
      );
    });

    test(
      'uses commune or landmark as client anchor when district is empty',
      () {
        final withCommune = OrderDeliveryContact(
          address: 'Maison',
          district: '',
          commune: 'Matoto',
          instructions: 'en face école primaire',
          phoneNumber: '',
        );

        final withLandmark = OrderDeliveryContact(
          address: '',
          district: '',
          commune: '',
          instructions: 'près de la mosquée, derrière le marché',
          phoneNumber: '',
        );

        expect(
          MapQueryBuilder.buildClientQuery(withCommune),
          'Matoto, en face école primaire, Conakry, Guinée',
        );
        expect(
          MapQueryBuilder.buildClientQuery(withLandmark),
          'près de la mosquée, derrière le marché, Conakry, Guinée',
        );
      },
    );

    test('removes fake or generic client addresses', () {
      final contact = OrderDeliveryContact(
        address: '12 rue inconnue',
        district: '',
        commune: '',
        instructions: '',
        phoneNumber: '',
      );

      expect(MapQueryBuilder.buildClientQuery(contact), 'Conakry, Guinée');
    });

    test('builds restaurant query and avoids duplicated city or country', () {
      expect(
        MapQueryBuilder.buildRestaurantQuery(
          restaurantName: '  Le Goût  ',
          pickupAddress: 'Kipé - Conakry - Guinée',
        ),
        'Le Goût, Kipé, Conakry, Guinée',
      );
    });

    test('does not repeat restaurant name already present in address', () {
      expect(
        MapQueryBuilder.buildRestaurantQuery(
          restaurantName: 'Dineroo Food',
          pickupAddress: 'Dineroo Food, Ratoma',
        ),
        'Dineroo Food, Conakry, Guinée',
      );
    });

    test('falls back to Conakry Guinea for generic restaurant query', () {
      expect(
        MapQueryBuilder.buildRestaurantQuery(
          restaurantName: '',
          pickupAddress: 'domicile',
        ),
        'Conakry, Guinée',
      );
    });

    test('builds client label from name, district, and commune', () {
      final contact = OrderDeliveryContact(
        firstName: 'Aminata',
        lastName: 'Diallo',
        address: '',
        district: 'Kipé',
        commune: 'Ratoma',
        phoneNumber: '',
      );

      expect(
        MapQueryBuilder.buildClientLabel(contact),
        'Aminata • Kipé • Ratoma',
      );
    });

    test('builds client label fallback without duplicate commune', () {
      final contact = OrderDeliveryContact(
        address: '',
        district: 'Ratoma',
        commune: ' ratoma ',
        phoneNumber: '',
      );

      expect(MapQueryBuilder.buildClientLabel(contact), 'Ratoma');
      expect(MapQueryBuilder.buildClientLabel(null), 'Client');
    });
  });
}
