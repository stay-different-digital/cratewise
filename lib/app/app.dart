import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../infrastructure/local_database/app_database.dart';
import '../l10n/app_localizations.dart';
import 'app_repositories.dart';
import 'locale_preference.dart';
import 'router.dart';
import 'theme.dart';

class LocaleScope extends InheritedNotifier<ValueNotifier<Locale?>> {
  const LocaleScope({
    super.key,
    required ValueNotifier<Locale?> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<Locale?> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!.notifier!;

  static ValueNotifier<Locale?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}

class CratewiseApp extends StatefulWidget {
  const CratewiseApp({super.key, this.showOnboarding = false});

  final bool showOnboarding;

  @override
  State<CratewiseApp> createState() => _CratewiseAppState();
}

class _CratewiseAppState extends State<CratewiseApp> {
  late final AppDatabase _database;
  late final AppRepositories _repositories;
  late final GoRouter _router = createAppRouter(
    showOnboarding: widget.showOnboarding,
  );
  final _localeNotifier = ValueNotifier<Locale?>(null);

  @override
  void initState() {
    super.initState();
    _database = AppDatabase(openAppDatabase());
    _repositories = AppRepositories(_database);
    _localeNotifier.addListener(() => setState(() {}));
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await loadLocalePreference();
    if (mounted) _localeNotifier.value = locale;
  }

  @override
  void dispose() {
    _router.dispose();
    _database.close();
    _localeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      notifier: _localeNotifier,
      child: AppRepositoriesScope(
        repositories: _repositories,
        child: MaterialApp.router(
          title: 'Cratewise',
          debugShowCheckedModeBanner: false,
          theme: buildCratewiseTheme(Brightness.light),
          darkTheme: buildCratewiseTheme(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _localeNotifier.value,
          routerConfig: _router,
        ),
      ),
    );
  }
}
