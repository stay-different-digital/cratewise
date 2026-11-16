import 'package:flutter/foundation.dart';

/// Incremented when the Search tab is tapped while it is already the selected
/// tab (US-139). The search screen listens and, if it is on top of its tab,
/// clears the search box for a fresh search.
final searchTabReselectedNotifier = ValueNotifier<int>(0);
