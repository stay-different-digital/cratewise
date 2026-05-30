# Flutter Folder Setup Prompt for Crate

## Purpose

Use this prompt to create or validate the initial folder structure for the Crate Flutter app.

## Prompt

You are my senior Flutter architect.

Create the initial folder structure for `Crate`, a Flutter app for iPhone, iPad, Android phones, and Android tablets.

The app uses:

- Flutter
- Dart
- Riverpod
- go_router
- dio
- flutter_secure_storage
- freezed
- json_serializable
- mobile_scanner
- flutter_test
- integration_test

## Goal

Set up a clean, scalable, feature-based folder structure for the Crate app.

The app uses the Discogs API v2.0 and Discogs OAuth login.

The first product focus is collection management.

## Required Architecture

Use clean architecture with:

- Presentation layer
- Application layer
- Domain layer
- Data layer

Use feature-based folders.

## Required Folder Structure

Create or describe this structure:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    bootstrap.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
  core/
    api/
      discogs_api_client.dart
      api_headers.dart
      api_rate_limit.dart
      api_response.dart
    config/
      app_config.dart
      environment.dart
    errors/
      app_exception.dart
      failure.dart
      error_mapper.dart
    network/
      network_info.dart
    storage/
      secure_token_storage.dart
      token_storage.dart
    utils/
      result.dart
      date_formatter.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_error_state.dart
      app_empty_state.dart
      app_loading_state.dart
      app_release_card.dart
      app_filter_chip.dart
  features/
    auth/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
    collection/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
    release_detail/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
    search/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
    barcode_scanner/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
    wantlist/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
    settings/
      data/
        datasources/
        repositories/
        models/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        screens/
        widgets/
  shared/
    models/
    widgets/
    extensions/
```

Also create this test structure:

```text
test/
  core/
  features/
    auth/
    collection/
    release_detail/
    search/
    barcode_scanner/
    wantlist/
    settings/

integration_test/
  app_flow_test.dart
```

## Required Starter Files

Create starter files for:

- `main.dart`
- `app.dart`
- `router.dart`
- `app_theme.dart`
- `discogs_api_client.dart`
- `secure_token_storage.dart`
- `app_exception.dart`
- `failure.dart`
- `result.dart`
- `app_loading_state.dart`
- `app_empty_state.dart`
- `app_error_state.dart`
- `app_release_card.dart`

## Code Rules

Use production-ready code.

Do not hardcode Discogs secrets.

Use Discogs API v2.0 only.

Add comments only where useful.

Use clear names.

Keep files small.

Use Riverpod providers where useful.

Use go_router for navigation.

Use secure storage only through an abstraction.

## Output Format

Respond with:

1. Folder structure
2. Package recommendations
3. File creation commands
4. Starter code for the most important files
5. Notes about OAuth security
6. First tests to add
