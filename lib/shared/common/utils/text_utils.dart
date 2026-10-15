/// Capitalize the first letter of a word
String capitalize(String text) {
  if (text.isEmpty) return text;
  return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
}

/// Returns the first non-empty word from a full name.
/// Fallback to [fallback] if no usable first name is found
String extractFirstName(String? value, {String fallback = 'Client'}) {
  final cleaned = (value ?? '').trim();
  if (cleaned.isEmpty) return fallback;
  final parts =
      cleaned.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return fallback;
  return parts.first;
}
