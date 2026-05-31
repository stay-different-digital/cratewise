import 'package:flutter/widgets.dart';

import '../presentation/screens/home_shell_screen.dart';

Route<void> buildHomeRoute() {
  return PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const HomeShellScreen(),
  );
}
