import 'package:flutter/material.dart';

final appRouteObserver = RouteObserver<ModalRoute<dynamic>>();
final wishlistRouteObserver = RouteObserver<ModalRoute<dynamic>>();

/// Observes the Search branch so the search results can re-resolve
/// collection/wishlist membership when the user returns from a release
/// detail screen (US-80).
final searchRouteObserver = RouteObserver<ModalRoute<dynamic>>();
