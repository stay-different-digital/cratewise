class DiscogsSearchPageDto {
  const DiscogsSearchPageDto({
    required this.results,
    required this.currentPage,
    required this.totalPages,
    required this.totalResults,
  });

  final List<DiscogsSearchResultDto> results;
  final int currentPage;
  final int totalPages;
  final int totalResults;

  factory DiscogsSearchPageDto.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    final resultsJson = json['results'] as List<dynamic>? ?? [];
    return DiscogsSearchPageDto(
      results: resultsJson
          .map(
            (e) => DiscogsSearchResultDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      currentPage: (pagination['page'] as int?) ?? 1,
      totalPages: (pagination['pages'] as int?) ?? 1,
      totalResults: (pagination['items'] as int?) ?? 0,
    );
  }
}

class DiscogsSearchResultDto {
  const DiscogsSearchResultDto({
    required this.id,
    required this.artist,
    required this.title,
    required this.format,
    required this.label,
    required this.country,
    this.year,
    this.thumbUrl,
  });

  final int id;
  final String artist;
  final String title;
  final String format;
  final String label;
  final String country;
  final int? year;
  final String? thumbUrl;

  factory DiscogsSearchResultDto.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title'] as String?) ?? '';

    // Prefer a dedicated artist field when the API provides one.
    // Otherwise split the combined "Artist - Title" string on the last " - "
    // so artist names that themselves contain " - " are handled correctly.
    final dedicatedArtist = json['artist'] as String?;
    final String artist;
    final String title;
    if (dedicatedArtist != null && dedicatedArtist.isNotEmpty) {
      artist = dedicatedArtist;
      title = rawTitle;
    } else {
      final sep = rawTitle.lastIndexOf(' - ');
      artist = sep >= 0 ? rawTitle.substring(0, sep) : '';
      title = sep >= 0 ? rawTitle.substring(sep + 3) : rawTitle;
    }

    final formats = json['format'] as List<dynamic>?;
    final labels = json['label'] as List<dynamic>?;
    final yearStr = json['year'] as String?;
    final thumb = json['thumb'] as String?;

    return DiscogsSearchResultDto(
      id: json['id'] as int,
      artist: artist,
      title: title,
      format: (formats != null && formats.isNotEmpty)
          ? formats.first as String
          : '',
      label: (labels != null && labels.isNotEmpty)
          ? labels.first as String
          : '',
      country: (json['country'] as String?) ?? '',
      year: yearStr != null ? int.tryParse(yearStr) : null,
      thumbUrl: (thumb != null && thumb.isNotEmpty) ? thumb : null,
    );
  }
}
