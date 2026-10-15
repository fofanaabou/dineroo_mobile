import 'package:dineroo_mobile/shared/models/domain/order_delivery_contact.dart';

class MapQueryBuilder {
  static const String _city = 'Conakry';
  static const String _country = 'Guinée';

  static String buildClientQuery(OrderDeliveryContact? contact) {
    if (contact == null) return '$_city, $_country';
    final district = _normalizePlace(contact.district);
    final commune = _normalizePlace(contact.commune);
    final address = _normalizeAddress(contact.address);
    final instructions = _normalizeInstructions(contact.instructions);

    final anchor = _extractBestAnchor(
      district: district,
      commune: commune,
      address: address,
      instructions: instructions,
    );

    final secondaryHints = <String>[
      if (district.isNotEmpty && !_sameValue(district, anchor)) district,
      if (commune.isNotEmpty && !_sameValue(commune, anchor)) commune,
      if (address.isNotEmpty && !_sameValue(address, anchor)) address,
    ];

    final landmarkHints = _extractLandmarkHints(instructions);

    final parts = <String>[
      if (anchor.isNotEmpty) anchor,
      ...landmarkHints,
      ...secondaryHints,
      _city,
      _country,
    ];
    return _deduplicate(parts).join(', ');
  }

  static String buildRestaurantQuery({
    required String restaurantName,
    required String pickupAddress,
  }) {
    final cleanName = _normalizePlace(restaurantName);
    final cleanAddress = _normalizeRestaurantAddress(pickupAddress);

    final parts = <String>[
      if (cleanName.isNotEmpty) cleanName,
      if (cleanAddress.isNotEmpty &&
          !_addressContainsName(cleanAddress, cleanName))
        cleanAddress,
    ];
    final normalized = _deduplicate(parts).join(', ');
    return _ensureConakryGuinea(normalized);
  }

  static String buildClientLabel(OrderDeliveryContact? contact) {
    if (contact == null) return 'Client';
    final name = contact.shortDisplayName.trim();
    final district = _normalizePlace(contact.district);
    final commune = _normalizePlace(contact.commune);

    final parts = <String>[
      if (name.isNotEmpty && name.toLowerCase() != 'client') name,
      if (district.isNotEmpty) district,
      if (commune.isNotEmpty && !_sameValue(commune, district)) commune,
    ];
    return parts.isNotEmpty ? parts.join(' • ') : 'Client';
  }

  static String _extractBestAnchor({
    required String district,
    required String commune,
    required String address,
    required String instructions,
  }) {
    if (district.isNotEmpty) return district;
    if (commune.isNotEmpty) return commune;

    final landmarkHints = _extractLandmarkHints(instructions);
    if (landmarkHints.isNotEmpty) return landmarkHints.first;
    if (address.isNotEmpty) return address;
    return _city;
  }

  static List<String> _extractLandmarkHints(String instructions) {
    if (instructions.isEmpty) return const [];
    final cleaned =
        instructions
            .replaceAll(RegExp(r'[;|]+'), ',')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    if (cleaned.isEmpty) return const [];

    final chunks =
        cleaned
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final prioritized = <String>[];

    for (final chunk in chunks) {
      final lower = chunk.toLowerCase();

      final hasLandmarkKeyword =
          lower.contains('près de') ||
          lower.contains('pres de') ||
          lower.contains('à côté') ||
          lower.contains('a cote') ||
          lower.contains('en face') ||
          lower.contains('rond-point') ||
          lower.contains('rond point') ||
          lower.contains('carrefour') ||
          lower.contains('marché') ||
          lower.contains('marche') ||
          lower.contains('mosquée') ||
          lower.contains('mosquee') ||
          lower.contains('pharmacie') ||
          lower.contains('station') ||
          lower.contains('école') ||
          lower.contains('ecole') ||
          lower.contains('gare') ||
          lower.contains('pont');

      if (hasLandmarkKeyword || chunk.split(' ').length <= 6) {
        prioritized.add(chunk);
      }
    }
    return _deduplicate(prioritized).take(2).toList();
  }

  static String _normalizePlace(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '';

    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _normalizeInstructions(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '';

    return trimmed
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(
            r'^(adresse|indication|instructions?)\s*:\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static String _normalizeAddress(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final compact = _cleanLocationText(trimmed);
    if (_looksLikeFakeStreetAddress(compact)) {
      return '';
    }
    if (_looksTooGeneric(compact)) {
      return '';
    }
    return compact;
  }

  static String _normalizeRestaurantAddress(String value) {
    final compact = _cleanLocationText(value);
    if (compact.isEmpty) return '';
    if (_looksTooGeneric(compact)) {
      return '';
    }
    return compact;
  }

  static String _cleanLocationText(String value) {
    var result = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    result = result.replaceAll(RegExp(r'\s*-\s*'), ', ');
    result = result.replaceAll(RegExp(r'\s*,\s*'), ', ');
    result = result.replaceAll(RegExp(r'(,\s*)+'), ', ');

    final parts =
        result
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final cleanedParts = <String>[];
    for (final part in parts) {
      final lower = part.toLowerCase();

      final isCountryOnly = lower == 'guinée' || lower == 'guinee';
      final isCityOnly = lower == 'conakry';
      final isConakryGuinea =
          lower == 'conakry - guinée' ||
          lower == 'conakry guinée' ||
          lower == 'conakry guinea';

      if (isCountryOnly || isCityOnly || isConakryGuinea) {
        continue;
      }
      cleanedParts.add(part);
    }
    return _deduplicate(cleanedParts).join(', ');
  }

  static String _ensureConakryGuinea(String value) {
    final parts =
        value
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final hasConakry = parts.any((e) => e.toLowerCase() == 'conakry');
    final hasGuinea = parts.any(
      (e) => e.toLowerCase() == 'guinée' || e.toLowerCase() == 'guinee',
    );

    if (!hasConakry) parts.add(_city);
    if (!hasGuinea) parts.add(_country);

    return _deduplicate(parts).join(', ');
  }

  static bool _looksLikeFakeStreetAddress(String value) {
    final lower = value.toLowerCase();
    return RegExp(
          r'^\d+\s+(rue|avenue|av|bd|boulevard)\b',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r'^(rue|avenue|av|bd|boulevard)\s+[a-z]',
          caseSensitive: false,
        ).hasMatch(lower);
  }

  static bool _looksTooGeneric(String value) {
    final lower = value.toLowerCase();
    const genericValues = {
      'domicile',
      'maison',
      'chez moi',
      'quartier',
      'adresse',
      'inconnu',
      'unknown',
      'n/a',
      '-',
    };
    return genericValues.contains(lower);
  }

  static bool _addressContainsName(String address, String name) {
    if (address.isEmpty || name.isEmpty) return false;

    final normalizedAddress = address.toLowerCase();
    final normalizedName = name.toLowerCase();

    return normalizedAddress.contains(normalizedName);
  }

  static bool _sameValue(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static List<String> _deduplicate(List<String> values) {
    final seen = <String>{};
    final result = <String>[];

    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;

      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        result.add(normalized);
      }
    }
    return result;
  }
}
