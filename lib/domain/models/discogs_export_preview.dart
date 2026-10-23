/// What collection and wishlist Discogs exports have in common, so one
/// preview screen serves both (US-130).
abstract interface class DiscogsExportPreview {
  int get totalCount;
  int get eligibleCount;
  int get alreadySyncedCount;
  int get invalidCount;
}

abstract interface class DiscogsExportDone {
  int get exported;
  int get skipped;
  int get failed;
}
