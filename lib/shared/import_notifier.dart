import 'package:flutter/foundation.dart';

/// Incremented each time a collection import (Discogs or CSV) completes
/// successfully. Screens in other navigation branches listen to this to
/// reload their data without requiring a full rebuild.
final collectionImportNotifier = ValueNotifier<int>(0);

/// Incremented each time a wishlist import (Discogs or CSV) completes
/// successfully.
final wishlistImportNotifier = ValueNotifier<int>(0);
