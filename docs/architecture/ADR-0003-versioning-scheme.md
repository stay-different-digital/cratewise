# ADR-0003: Versioning Scheme — Major.Minor.ServiceRelease.BuildNR

## Status

Accepted

## Context

Cratewise needs a versioning scheme that:

- Is human-readable in the UI (settings screen, onboarding screen).
- Maps cleanly to the Flutter `pubspec.yaml` `version` field.
- Distinguishes between a new publishable release and a build iteration of
  that release.

## Decision

Use **`Major.Minor.ServiceRelease.BuildNR`** as the canonical version format,
stored in `pubspec.yaml` as `Major.Minor.ServiceRelease+BuildNR`.

| Segment        | When to increment                                         | Reset on increment |
|----------------|-----------------------------------------------------------|--------------------|
| Major          | Breaking redesign or major milestone (e.g. 2.0 rewrite). | Minor, ServiceRelease, BuildNR → 0/1 |
| Minor          | Significant feature batch shipped to users.               | ServiceRelease → 0, BuildNR → 1 |
| ServiceRelease | Any code change that produces a new release to users.     | BuildNR → 1        |
| BuildNR        | Each CI/CD build iteration of the same ServiceRelease.    | —                  |

**Displayed format:** `1.0.3.12` (dot-separated, no `+`).
**pubspec.yaml storage:** `version: 1.0.3+12`.

`package_info_plus` is used to read `version` and `buildNumber` at runtime,
so the version shown in the UI is never hardcoded.

### Example

```
1.0.0+1   First release candidate build
1.0.0+2   Second build iteration, same release (BuildNR bumped)
1.0.1+1   Bug-fix release shipped to users (ServiceRelease bumped, BuildNR reset)
1.1.0+1   New feature batch (Minor bumped, ServiceRelease and BuildNR reset)
```

### Display format helper

The UI renders the version as `${info.version}.${info.buildNumber}`, which
produces e.g. `1.0.1.3` from `version: 1.0.1+3` in `pubspec.yaml`.

## Consequences

Positive:

- Four-segment format is familiar to both developers and support staff.
- `pubspec.yaml` requires no extra tooling — `Major.Minor.ServiceRelease+BuildNR`
  is the native Flutter format.
- BuildNR serves as a monotonically increasing CI/CD sequence number, making
  it easy to correlate crash reports with specific builds.

Negative:

- Developers must increment ServiceRelease (and reset BuildNR to 1 in
  `pubspec.yaml`) before each release to users. Minor is bumped manually for
  significant feature batches. These are intentional human decisions.
- BuildNR in `pubspec.yaml` is a baseline only; CI overrides it at build time
  with `--build-number=${{ github.run_number }}` so every CI binary gets a
  unique, monotonically increasing number automatically.
