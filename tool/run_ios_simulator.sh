#!/usr/bin/env bash
# Builds Cratewise for one iOS simulator and launches it there.
#
# `flutter build ios --simulator` (Flutter 3.50, Xcode SDK 27) fails in
# Flutter's framework-copy step: it expects the architectures "arm64 x86_64"
# while lipo reports "x86_64 arm64". Building for a single simulator with
# ONLY_ACTIVE_ARCH=YES avoids that check.
#
# Usage: tool/run_ios_simulator.sh [simulator-udid]   (default: first booted
# or first available iPhone)
set -euo pipefail
cd "$(dirname "$0")/.."

udid="${1:-}"
if [[ -z "$udid" ]]; then
  udid=$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1 || true)
fi
if [[ -z "$udid" ]]; then
  udid=$(xcrun simctl list devices available | grep iPhone | grep -Eo '[0-9A-F-]{36}' | head -1)
fi
xcrun simctl boot "$udid" 2>/dev/null || true

flutter pub get >/dev/null
derived="build/ios-sim-derived"
(cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -destination "platform=iOS Simulator,id=$udid" \
  ONLY_ACTIVE_ARCH=YES -derivedDataPath "../$derived" build -quiet)

app="$derived/Build/Products/Debug-iphonesimulator/Runner.app"
xcrun simctl install "$udid" "$app"
xcrun simctl launch "$udid" app.cratewise
echo "Launched on simulator $udid"
