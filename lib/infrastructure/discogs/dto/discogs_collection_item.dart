class DiscogsCollectionPageDto {
  const DiscogsCollectionPageDto({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.items,
  });

  final int page;
  final int totalPages;
  final int totalItems;
  final List<DiscogsCollectionItemDto> items;

  factory DiscogsCollectionPageDto.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final releases = json['releases'] as List<dynamic>? ?? [];
    return DiscogsCollectionPageDto(
      page: (pagination['page'] as int?) ?? 1,
      totalPages: (pagination['pages'] as int?) ?? 1,
      totalItems: (pagination['items'] as int?) ?? 0,
      items: releases
          .map((r) =>
              DiscogsCollectionItemDto.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DiscogsCollectionItemDto {
  const DiscogsCollectionItemDto({
    required this.releaseId,
    required this.instanceId,
    required this.dateAdded,
    required this.rating,
    required this.folderId,
    required this.title,
    required this.artist,
    required this.label,
    required this.catno,
    required this.format,
    required this.genres,
    this.year,
    this.thumbUrl,
  });

  final int releaseId;
  final int instanceId;
  final String dateAdded;
  final int rating;
  final int folderId;
  final String title;
  final String artist;
  final String label;
  final String catno;
  final String format;
  final List<String> genres;
  final int? year;
  final String? thumbUrl;

  factory DiscogsCollectionItemDto.fromJson(Map<String, dynamic> json) {
    final info = json['basic_information'] as Map<String, dynamic>? ?? {};

    final rawArtists = info['artists'] as List<dynamic>?;
    final artist = rawArtists != null && rawArtists.isNotEmpty
        ? rawArtists
            .map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ')
        : '';

    final rawLabels = info['labels'] as List<dynamic>?;
    final firstLabel = rawLabels != null && rawLabels.isNotEmpty
        ? rawLabels.first as Map<String, dynamic>
        : null;
    final label =
        firstLabel != null ? (firstLabel['name'] as String?) ?? '' : '';
    final catno =
        firstLabel != null ? (firstLabel['catno'] as String?) ?? '' : '';

    final rawFormats = info['formats'] as List<dynamic>?;
    final firstFormat = rawFormats != null && rawFormats.isNotEmpty
        ? rawFormats.first as Map<String, dynamic>
        : null;
    final String format;
    if (firstFormat != null) {
      final name = (firstFormat['name'] as String?) ?? '';
      final descriptions = (firstFormat['descriptions'] as List<dynamic>?)
              ?.map((d) => d as String)
              .toList() ??
          [];
      format =
          descriptions.isNotEmpty ? '$name, ${descriptions.join(', ')}' : name;
    } else {
      format = '';
    }

    final thumb = info['thumb'] as String?;

    return DiscogsCollectionItemDto(
      releaseId: (json['id'] as int?) ?? (info['id'] as int?) ?? 0,
      instanceId: (json['instance_id'] as int?) ?? 0,
      dateAdded: (json['date_added'] as String?) ?? '',
      rating: (json['rating'] as int?) ?? 0,
      folderId: (json['folder_id'] as int?) ?? 0,
      title: (info['title'] as String?) ?? '',
      artist: artist,
      label: label,
      catno: catno,
      format: format,
      genres:
          (info['genres'] as List<dynamic>?)?.map((g) => g as String).toList() ??
              [],
      year: info['year'] as int?,
      thumbUrl: (thumb != null && thumb.isNotEmpty) ? thumb : null,
    );
  }
}
