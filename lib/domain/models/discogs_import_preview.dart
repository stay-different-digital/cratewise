/// What collection and wishlist Discogs imports have in common, so one
/// preview screen serves both (US-130).
abstract interface class DiscogsImportPreview {
  int get totalCount;
  int get newCount;
  int get duplicateCount;
  int get invalidCount;
  int get conflictCount;
}

abstract interface class DiscogsImportDone {
  int get imported;
  int get linked;
  int get skipped;
  int get failed;
}
