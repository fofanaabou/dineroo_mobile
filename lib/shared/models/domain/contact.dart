class Contact {
  final String name;
  final String? imageUrl;
  final String? subtitle;
  final String phoneNumber;

  Contact({
    required this.name,
    this.imageUrl,
    this.subtitle,
    required this.phoneNumber,
  });

  String get displayName {
    final value = name.trim();
    return value.isNotEmpty ? value : 'Client';
  }
}
