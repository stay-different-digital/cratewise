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
    final sep = rawTitle.indexOf(' - ');
    final artist = sep >= 0 ? rawTitle.substring(0, sep) : '';
    final title = sep >= 0 ? rawTitle.substring(sep + 3) : rawTitle;

    final formats = json['format'] as List<dynamic>?;
    final labels = json['label'] as List<dynamic>?;
    final yearStr = json['year'] as String?;
    final thumb = json['thumb'] as String?;

    return DiscogsSearchResultDto(
      id: json['id'] as int,
      artist: artist,
      title: title,
      format: (formats != null && formats.isNotEmpty) ? formats.first as String : '',
      label: (labels != null && labels.isNotEmpty) ? labels.first as String : '',
      country: (json['country'] as String?) ?? '',
      year: yearStr != null ? int.tryParse(yearStr) : null,
      thumbUrl: (thumb != null && thumb.isNotEmpty) ? thumb : null,
    );
  }
}
