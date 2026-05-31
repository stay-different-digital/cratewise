class ReleaseSearchResult {
  const ReleaseSearchResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.format,
    required this.label,
    required this.country,
    this.year,
    this.coverUrl,
  });

  final int id;
  final String title;
  final String artist;
  final String format;
  final String label;
  final String country;
  final int? year;
  final String? coverUrl;
}
