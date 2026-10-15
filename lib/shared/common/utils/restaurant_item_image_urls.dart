Map<String, String> extractRestaurantItemImageUrls(Map<String, dynamic> json) {
  final imageUrls = <String, String>{};

  void collect(dynamic rawItems) {
    if (rawItems is! List) return;
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) continue;
      final id = rawItem['id']?.toString() ?? '';
      final imageUrl = rawItem['imageUrl']?.toString() ?? '';
      if (id.isNotEmpty && imageUrl.isNotEmpty) {
        imageUrls[id] = imageUrl;
      }
    }
  }

  collect(json['menus']);
  collect(json['products']);

  return imageUrls;
}
