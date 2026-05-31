import 'package:flutter/widgets.dart';

import '../presentation/screens/home_shell_screen.dart';

abstract final class AppRoutes {
  static const search = '/search';
  static const collection = '/collection';
  static const wishlist = '/wishlist';
  static const barcodeScan = '/barcode-scan';
  static const settings = '/settings';
}

Route<void> buildHomeRoute() {
  return PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const HomeShellScreen(),
  );
}
