# ADR 0011: Use mobile_scanner for Barcode Scanning

## Status

Accepted

## Date

2026-05-30

## Context

Barcode scanning is part of the MVP direction. The project needs a Flutter package for barcode scanning on iOS and Android.

## Decision

Use mobile_scanner for barcode scanning.

## Consequences

### Positive

- Supports barcode and QR scanning.
- Works with Flutter.
- Fits the barcode scanner feature.
- Keeps scanning implementation focused.

### Negative

- Requires camera permission handling.
- Must be tested on real devices.

## Alternatives Considered

### Build scanner from scratch

Rejected. It is not needed for MVP.

### Use another package

Deferred. Reconsider only if mobile_scanner blocks the project.

## Follow-up Actions

- Add camera permission flow.
- Add manual fallback.
- Add real-device testing checklist.
