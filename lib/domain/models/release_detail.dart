class ReleaseTrack {
  const ReleaseTrack({
    required this.position,
    required this.title,
    required this.duration,
  });

  final String position;
  final String title;
  final String duration;
}

class ReleaseIdentifier {
  const ReleaseIdentifier({required this.type, required this.value});

  final String type;
  final String value;
}

class ReleaseDetail {
  const ReleaseDetail({
    required this.id,
    required this.title,
    required this.artist,
    required this.label,
    required this.catno,
    required this.format,
    required this.country,
    required this.genres,
    required this.styles,
    required this.tracklist,
    required this.identifiers,
    this.year,
    this.notes,
    this.coverUrl,
  });

  final int id;
  final String title;
  final String artist;
  final String label;
  final String catno;
  final String format;
  final String country;
  final int? year;
  final List<String> genres;
  final List<String> styles;
  final List<ReleaseTrack> tracklist;
  final String? notes;
  final String? coverUrl;
  final List<ReleaseIdentifier> identifiers;
}
