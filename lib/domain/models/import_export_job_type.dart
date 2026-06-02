enum ImportExportJobType {
  importCollectionFromDiscogs,
  importWishlistFromDiscogs,
  exportCollectionToDiscogs,
  exportWishlistToDiscogs,
  csvCollectionExport,
  csvWishlistExport,
  csvCollectionImport,
  csvWishlistImport;

  String get label => switch (this) {
        importCollectionFromDiscogs => 'Import collection from Discogs',
        importWishlistFromDiscogs => 'Import wishlist from Discogs',
        exportCollectionToDiscogs => 'Export collection to Discogs',
        exportWishlistToDiscogs => 'Export wishlist to Discogs',
        csvCollectionExport => 'Export collection to CSV',
        csvWishlistExport => 'Export wishlist to CSV',
        csvCollectionImport => 'Import collection from CSV',
        csvWishlistImport => 'Import wishlist from CSV',
      };
}
