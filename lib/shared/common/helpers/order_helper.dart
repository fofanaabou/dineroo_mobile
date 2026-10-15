String getShortOrderId(dynamic id) {
  final value = id?.toString().trim() ?? '';
  final lastSegment = value.split('-').last;
  return lastSegment.isEmpty ? value : lastSegment;
}

String formatOrderReference(dynamic id) {
  final shortId = getShortOrderId(id);
  return shortId.isEmpty ? 'Commande' : 'Commande #$shortId';
}

String formatOrderReferenceNumber(dynamic id) {
  final shortId = getShortOrderId(id);
  return shortId.isEmpty ? '-' : '#$shortId';
}

/// Returns order name or "Commande #XXXX" if name is null/empty.
String getOrderDisplayName(dynamic id, [String? name]) {
  return (name?.trim().isNotEmpty == true) ? name! : formatOrderReference(id);
}

/// Returns item name or "Article #XXXXXX" if name is null/empty
String getOrderItemDisplayName(int id, [String? name]) {
  return (name?.trim().isNotEmpty == true) ? name! : 'Article #$id';
}
