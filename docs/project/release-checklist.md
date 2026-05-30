# Release Checklist

## Purpose

Use this checklist before creating a beta or production release for Crate.

## Release Info

Version:

```text
[Add version]
```

Release date:

```text
[Add date]
```

Release type:

- [ ] Internal test
- [ ] Beta
- [ ] Production

## Pre-release Checks

- [ ] Roadmap status checked.
- [ ] Backlog status checked.
- [ ] Changelog updated.
- [ ] ADRs checked.
- [ ] No secrets committed.
- [ ] Dependencies checked.
- [ ] App version updated.
- [ ] Build number updated.

## Flutter Checks

Run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Manual Test Checklist

### Auth

- [ ] Discogs OAuth login works.
- [ ] OAuth callback works.
- [ ] Logout works.
- [ ] Login error state works.

### Collection

- [ ] Collection overview loads.
- [ ] Collection list loads.
- [ ] Pagination works.
- [ ] Pull to refresh works.
- [ ] Search works.
- [ ] Filters work.
- [ ] Sorting works.

### Release Detail

- [ ] Release detail opens.
- [ ] Tracklist shows.
- [ ] Missing data is handled.
- [ ] Open in Discogs works.

### Theme

- [ ] Light mode works.
- [ ] Dark mode works.
- [ ] System mode works.

### Devices

- [ ] iPhone layout checked.
- [ ] iPad layout checked.
- [ ] Android phone layout checked.
- [ ] Android tablet layout checked.

## Final Decision

- [ ] Release approved
- [ ] Release blocked
