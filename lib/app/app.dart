import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

class CratewiseApp extends StatefulWidget {
  const CratewiseApp({super.key});

  @override
  State<CratewiseApp> createState() => _CratewiseAppState();
}

class _CratewiseAppState extends State<CratewiseApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cratewise',
      debugShowCheckedModeBanner: false,
      theme: buildCratewiseTheme(Brightness.light),
      darkTheme: buildCratewiseTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
