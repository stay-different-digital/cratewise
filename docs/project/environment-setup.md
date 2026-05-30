# Environment Setup

## Purpose

This document explains how to set up the Crate development environment.

## Requirements

Install:

- Flutter stable
- Dart
- Xcode for iOS builds
- Android Studio for Android builds
- A code editor
- Git

Check setup:

```bash
flutter doctor
```

## Clone Repository

```bash
git clone [repository-url]
cd [repository-folder]
```

## Install Dependencies

```bash
flutter pub get
```

## Run App

```bash
flutter run
```

## Run Checks

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Environment Variables

Copy:

```bash
cp .env.example .env
```

Fill in local values.

Important:

- Do not commit `.env`.
- Do not commit real secrets.
- Do not store the Discogs consumer secret in Flutter.

## Discogs API

Use Discogs API v2.0 only.

Do not use Discogs API v1.0.

Do not scrape Discogs.

## OAuth

Crate uses a Cloudflare Worker for Discogs OAuth and signed API calls.

The Flutter app must not store the Discogs consumer secret.

Expected local values:

```bash
CRATE_WORKER_BASE_URL=
CRATE_APP_SCHEME=crate
```

Discogs secrets belong in Cloudflare Worker secrets, not in Flutter.
