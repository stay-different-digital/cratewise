import 'package:flutter/foundation.dart';

/// Incremented to ask for an automatic Discogs sync run right away, bypassing
/// the 15-minute throttle — e.g. just after the user turns auto-sync on
/// (US-148). [DiscogsAutoSyncRunner] listens.
final autoSyncRequestNotifier = ValueNotifier<int>(0);
