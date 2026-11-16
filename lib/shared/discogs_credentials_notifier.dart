import 'package:flutter/foundation.dart';

/// Incremented whenever the stored Discogs credentials change: connected,
/// disconnected, or cleared after Discogs rejected the token. Widgets that
/// depend on "is an account linked?" (e.g. the auto-sync switch, US-144)
/// listen to reload without a rebuild of their screen.
final discogsCredentialsNotifier = ValueNotifier<int>(0);
