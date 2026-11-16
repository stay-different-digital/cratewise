/// Format types (Vinyl, CD, File, …) in a stored Discogs format string
/// (US-143).
///
/// The format of a collection/wishlist item is one line per Discogs format
/// entry, each `name, description, description…` — e.g.
/// `Vinyl, LP, Album\nFile, MP3, 320 kbps`. The type is the name before the
/// first comma of each line. Returned in order, without duplicates, so
/// `.first` is the primary format; empty for a null or blank format.
List<String> formatTypes(String? format) {
  if (format == null) return const [];
  final types = <String>[];
  for (final line in format.split('\n')) {
    final type = line.split(',').first.trim();
    if (type.isNotEmpty && !types.contains(type)) types.add(type);
  }
  return types;
}
