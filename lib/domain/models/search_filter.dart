/// Which Discogs field a text search should match (US-84 / US-85).
///
/// [all] is the default — no chip selected — and searches every field via the
/// general `q` query. The other values scope the query to a single field. US-84
/// adds the chip UI and selected-filter state; US-85 makes the selection
/// actually scope the Discogs query.
enum SearchFilter {
  all,
  release,
  artist,
  label;

  /// Label shown on the filter chip. [all] has no chip (it is the implicit
  /// "nothing selected" state), so it has no chip label of its own.
  String get chipLabel => switch (this) {
    SearchFilter.all => 'All',
    SearchFilter.release => 'Release',
    SearchFilter.artist => 'Artist',
    SearchFilter.label => 'Label',
  };
}
