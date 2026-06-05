import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class CratewiseApp extends StatelessWidget {
  const CratewiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cratewise',
      debugShowCheckedModeBanner: false,
      theme: buildCratewiseTheme(Brightness.light),
      darkTheme: buildCratewiseTheme(Brightness.dark),
      routerConfig: appRouter,
    );
  }
}
