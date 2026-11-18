#!/usr/bin/env bash
# Runs the same checks as .github/workflows/flutter-ci.yml on this machine,
# so day-to-day checks cost no GitHub Actions minutes (US-168).
#
# Usage: tool/ci_local.sh [--skip-ios]
# Stops at the first failing step and names it. Uses no tokens or .env.
set -uo pipefail
cd "$(dirname "$0")/.."

skip_ios=false
for arg in "$@"; do
  case "$arg" in
    --skip-ios) skip_ios=true ;;
    -h | --help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# Android builds need JDK 21; fall back to the one bundled with Android Studio.
if [[ -z "${JAVA_HOME:-}" ]]; then
  studio_jbr="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  [[ -d "$studio_jbr" ]] && export JAVA_HOME="$studio_jbr"
fi

log_dir=$(mktemp -d)
step() {
  local name=$1; shift
  printf '▶ %s… ' "$name"
  local log="$log_dir/$(echo "$name" | tr ' /' '__').log"
  if "$@" >"$log" 2>&1; then
    echo "ok"
  else
    echo "FAILED"
    tail -40 "$log"
    echo "✗ CI failed at step: $name (full log: $log)" >&2
    exit 1
  fi
}

no_kgp() {
  if grep -q "apply Kotlin Gradle Plugin (KGP)" "$log_dir/Build_Android_release.log"; then
    grep -A1 "apply Kotlin Gradle Plugin (KGP)" "$log_dir/Build_Android_release.log"
    return 1
  fi
}

step "Install dependencies" flutter pub get
step "Check formatting" dart format --output=none --set-exit-if-changed .
step "Analyze" flutter analyze
step "Run tests" flutter test
step "Build Android release" flutter build apk --release
step "No plugins applying KGP" no_kgp
if [[ "$skip_ios" == false ]]; then
  step "Build iOS debug (no codesign)" flutter build ios --debug --no-codesign
fi

echo "✓ All CI checks passed"
