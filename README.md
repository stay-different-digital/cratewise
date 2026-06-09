# Cratewise

Cratewise is a Flutter app for vinyl collectors and DJs.

It is an independent Discogs companion app. It uses the Discogs API, but it is
not affiliated with or endorsed by Discogs.

## Platforms

The app is set up for:

- Android phones
- iPhones
- iPads

Desktop and web targets are out of scope.

## Getting Started

Install Flutter, then run:

```bash
flutter doctor
flutter pub get
flutter run
```

Useful checks:

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

## Test the project

Run for iOS:

```bash
open -a Simulator
```

```bash
flutter run
```

Run for Android:

- Start android studio
- Go to virtual 
- Start a phone 

```bash
flutter run
```

## Project Structure

```text
lib/
  main.dart
  app/
  presentation/
  application/
  domain/
  infrastructure/
  shared/
test/
android/
ios/
```

## Security

Never hardcode Discogs tokens or API secrets. Tokens must be stored with secure
storage and masked in the UI.
