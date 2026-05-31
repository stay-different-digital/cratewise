# Architecture

## Goal

Keep Cratewise simple, modular, and testable.

## Layers

Use these layers:

- `presentation`
- `application`
- `domain`
- `infrastructure`
- `shared`

## Folder structure

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  presentation/
    screens/
    widgets/
    design_system/
  application/
    use_cases/
    state/
    services/
  domain/
    models/
    repositories/
    value_objects/
  infrastructure/
    discogs/
    local_database/
    secure_storage/
    sync/
    csv/
  shared/
    errors/
    utils/
    constants/
test/
```

## Dependency rule

Dependencies should point inward.

Allowed:

- Presentation uses application.
- Application uses domain.
- Infrastructure implements domain repository contracts.

Avoid:

- Widgets calling Discogs API directly.
- Widgets writing to database directly.
- Domain models depending on Flutter widgets.

## Recommended packages

Suggested package categories:

- State management: Riverpod
- Routing: GoRouter
- HTTP: Dio
- Secure storage: Flutter Secure Storage
- Local database: Drift or Isar
- Images: Cached Network Image
- Barcode: Mobile Scanner
- CSV: csv
- Files: File Picker and Path Provider

Pick final packages based on Android and iOS/iPadOS compatibility.

## Data model

Core models:

- User
- DiscogsAccount
- Release
- Artist
- Label
- Track
- CollectionItem
- WishlistItem
- BarcodeIdentifier
- CustomTag
- SyncStatus

## Error handling

Use typed app errors.

Examples:

- InvalidToken
- NoInternet
- RateLimited
- DiscogsUnavailable
- EmptyResult
- LocalDatabaseError
- ExportFailed
- ImportFailed

## Testing approach

Test domain and infrastructure first.

Prioritize:

- Token validation
- API mapping
- Repository behavior
- CSV import and export
- Sync status logic
