import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../infrastructure/local_database/app_database.dart';
import 'app_repositories.dart';
import 'router.dart';
import 'theme.dart';

class CratewiseApp extends StatefulWidget {
  const CratewiseApp({super.key});

  @override
  State<CratewiseApp> createState() => _CratewiseAppState();
}

class _CratewiseAppState extends State<CratewiseApp> {
  late final AppDatabase _database;
  late final AppRepositories _repositories;
  late final GoRouter _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    _database = AppDatabase(openAppDatabase());
    _repositories = AppRepositories(_database);
  }

  @override
  void dispose() {
    _router.dispose();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppRepositoriesScope(
      repositories: _repositories,
      child: MaterialApp.router(
        title: 'Cratewise',
        debugShowCheckedModeBanner: false,
        theme: buildCratewiseTheme(Brightness.light),
        darkTheme: buildCratewiseTheme(Brightness.dark),
        routerConfig: _router,
      ),
    );
  }
}
