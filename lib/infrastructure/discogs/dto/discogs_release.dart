class DiscogsTrackDto {
  const DiscogsTrackDto({
    required this.position,
    required this.title,
    required this.duration,
  });

  final String position;
  final String title;
  final String duration;

  factory DiscogsTrackDto.fromJson(Map<String, dynamic> json) {
    return DiscogsTrackDto(
      position: (json['position'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      duration: (json['duration'] as String?) ?? '',
    );
  }
}

class DiscogsIdentifierDto {
  const DiscogsIdentifierDto({required this.type, required this.value});

  final String type;
  final String value;

  factory DiscogsIdentifierDto.fromJson(Map<String, dynamic> json) {
    return DiscogsIdentifierDto(
      type: (json['type'] as String?) ?? '',
      value: (json['value'] as String?) ?? '',
    );
  }
}

class DiscogsReleaseDto {
  const DiscogsReleaseDto({
    required this.id,
    required this.title,
    required this.artist,
    required this.displayArtist,
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
    this.thumbUrl,
    this.imageUrls = const [],
  });

  final int id;
  final String title;

  /// Canonical artist name — used for storage and search.
  final String artist;

  /// Display name — uses ANV when the credited name differs from canonical.
  final String displayArtist;
  final String label;
  final String catno;
  final String format;
  final String country;
  final int? year;
  final List<String> genres;
  final List<String> styles;
  final List<DiscogsTrackDto> tracklist;
  final String? notes;
  final String? coverUrl;
  final String? thumbUrl;
  final List<String> imageUrls;
  final List<DiscogsIdentifierDto> identifiers;

  factory DiscogsReleaseDto.fromJson(Map<String, dynamic> json) {
    // Artist — canonical name from `name`; display name from `anv` when present
    final rawArtists = json['artists'] as List<dynamic>?;
    String artist = '';
    String displayArtist = '';
    if (rawArtists != null && rawArtists.isNotEmpty) {
      final maps = rawArtists.cast<Map<String, dynamic>>();
      artist = maps
          .map((a) => (a['name'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');
      displayArtist = maps
          .map((a) {
            final anv = (a['anv'] as String?) ?? '';
            return anv.isNotEmpty ? anv : ((a['name'] as String?) ?? '');
          })
          .where((n) => n.isNotEmpty)
          .join(', ');
    }

    // Label and catalog number — use first entry
    final rawLabels = json['labels'] as List<dynamic>?;
    final firstLabel = rawLabels != null && rawLabels.isNotEmpty
        ? rawLabels.first as Map<String, dynamic>
        : null;
    final label = firstLabel != null
        ? (firstLabel['name'] as String?) ?? ''
        : '';
    final catno = firstLabel != null
        ? (firstLabel['catno'] as String?) ?? ''
        : '';

    // Format — name + descriptions from all entries, joined with newline
    final rawFormats = json['formats'] as List<dynamic>?;
    final String format;
    if (rawFormats != null && rawFormats.isNotEmpty) {
      final entries = rawFormats
          .cast<Map<String, dynamic>>()
          .map((f) {
            final name = (f['name'] as String?) ?? '';
            final descriptions =
                (f['descriptions'] as List<dynamic>?)
                    ?.map((d) => d as String)
                    .toList() ??
                [];
            return descriptions.isNotEmpty
                ? '$name, ${descriptions.join(', ')}'
                : name;
          })
          .where((s) => s.isNotEmpty)
          .toList();
      format = entries.join('\n');
    } else {
      format = '';
    }

    // Cover image — prefer primary; fall back to first image
    final rawImages = json['images'] as List<dynamic>?;
    String? coverUrl;
    String? thumbUrl;
    final List<String> imageUrls = [];
    if (rawImages != null && rawImages.isNotEmpty) {
      final images = rawImages.map((i) => i as Map<String, dynamic>).toList();
      final primaryImages = images.where((i) => i['type'] == 'primary');
      final imageMap = primaryImages.isNotEmpty
          ? primaryImages.first
          : images.first;
      final uri = imageMap['uri'] as String?;
      final uri150 = imageMap['uri150'] as String?;
      coverUrl = (uri != null && uri.isNotEmpty) ? uri : null;
      thumbUrl = (uri150 != null && uri150.isNotEmpty) ? uri150 : null;
      // Collect all full-res URIs in API order for the gallery.
      for (final img in images) {
        final u = img['uri'] as String?;
        if (u != null && u.isNotEmpty) imageUrls.add(u);
      }
    }

    // Tracklist — skip section heading rows
    final rawTracklist = json['tracklist'] as List<dynamic>? ?? [];
    final tracklist = rawTracklist
        .map((t) => t as Map<String, dynamic>)
        .where((t) => (t['type_'] as String?) != 'heading')
        .map(DiscogsTrackDto.fromJson)
        .toList();

    // Identifiers
    final rawIdentifiers = json['identifiers'] as List<dynamic>? ?? [];
    final identifiers = rawIdentifiers
        .map((i) => DiscogsIdentifierDto.fromJson(i as Map<String, dynamic>))
        .toList();

    return DiscogsReleaseDto(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      artist: artist,
      displayArtist: displayArtist.isNotEmpty ? displayArtist : artist,
      label: label,
      catno: catno,
      format: format,
      country: (json['country'] as String?) ?? '',
      year: json['year'] as int?,
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => g as String)
              .toList() ??
          [],
      styles:
          (json['styles'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [],
      tracklist: tracklist,
      notes: json['notes'] as String?,
      coverUrl: coverUrl,
      thumbUrl: thumbUrl,
      imageUrls: imageUrls,
      identifiers: identifiers,
    );
  }
}
