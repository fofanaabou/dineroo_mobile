class Organization {
  final String id;
  final String name;

  Organization({required this.id, required this.name});

  factory Organization.fromToken(Map<String, dynamic> token) {
    final possibleKeys = [
      'organization',
      'organization-resto',
      'organizations',
      'org-info',
    ];

    MapEntry<String, dynamic>? selectedEntry;

    for (final key in possibleKeys) {
      final rawSection = token[key];
      if (rawSection is Map) {
        final entries = rawSection.entries.toList();
        if (entries.isNotEmpty) {
          final entry = entries.first;
          final castedEntry = MapEntry(entry.key.toString(), entry.value);
          selectedEntry = castedEntry;
          break;
        }
      }
    }

    if (selectedEntry == null) {
      return Organization(id: '', name: 'Mon Restaurant');
    }

    final name = selectedEntry.key;
    final id = (selectedEntry.value['id'] ?? '') as String;

    return Organization(id: id, name: name);
  }

  @override
  String toString() => 'Organization(id: $id, name: $name)';
}
