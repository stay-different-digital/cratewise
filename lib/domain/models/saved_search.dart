enum SavedSearchType {
  discogsSearch,
  collectionFilter,
  wishlistFilter;

  String get displayName => switch (this) {
    discogsSearch => 'Discogs search',
    collectionFilter => 'Collection filter',
    wishlistFilter => 'Wishlist filter',
  };
}

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.type,
    required this.payloadJson,
    required this.schemaVersion,
    required this.createdAt,
    required this.lastUsedAt,
  });

  final String id;
  final String name;
  final SavedSearchType type;
  final String payloadJson;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  SavedSearch copyWith({String? name, DateTime? lastUsedAt}) => SavedSearch(
    id: id,
    name: name ?? this.name,
    type: type,
    payloadJson: payloadJson,
    schemaVersion: schemaVersion,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}
