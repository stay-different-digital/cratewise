/// Sort order for the collection and the wishlist (US-163 / US-164): by the
/// date the record was added to the user's own collection or wishlist
/// (`createdAt`; for Discogs imports the date it was added on Discogs,
/// US-166). Not the edit date. One implementation for both screens.
enum AddedDateSort {
  newestFirst,
  oldestFirst;

  /// [items] ordered by [addedAt]. Items added at the same moment keep their
  /// relative order.
  List<T> apply<T>(List<T> items, DateTime Function(T item) addedAt) {
    final indexed = items.indexed.toList()
      ..sort((a, b) {
        final byDate = addedAt(a.$2).compareTo(addedAt(b.$2));
        final ordered = this == newestFirst ? -byDate : byDate;
        return ordered != 0 ? ordered : a.$1.compareTo(b.$1);
      });
    return [for (final (_, item) in indexed) item];
  }
}
