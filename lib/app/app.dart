import 'package:flutter/material.dart';

import '../presentation/screens/home_shell_screen.dart';
import 'theme.dart';

class CratewiseApp extends StatelessWidget {
  const CratewiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cratewise',
      debugShowCheckedModeBanner: false,
      theme: buildCratewiseTheme(Brightness.light),
      darkTheme: buildCratewiseTheme(Brightness.dark),
      home: const HomeShellScreen(),
    );
  }
}
