#!/usr/bin/env bash
# Builds the signed release APK and publishes it as a GitHub Release for an
# existing version tag (US-171). The APK is built and signed here; the
# signing key never goes to GitHub.
#
# Usage: tool/release.sh <version>      e.g. tool/release.sh 1.4.3
# Requires: tag v<version> on origin, pubspec.yaml at that version, gh login.
set -euo pipefail
cd "$(dirname "$0")/.."

version="${1:-}"
[[ -n "$version" ]] || { sed -n '2,8p' "$0"; exit 2; }
tag="v$version"
die() { echo "✗ $*" >&2; exit 1; }

# SHA-256 of the release signing certificate (public; not a secret).
release_cert="96f7bf0d6efe1f25681fdd4fce25762768f8a3dff62ff948854ebaa2d0e1ea09"

if [[ -z "${JAVA_HOME:-}" ]]; then
  studio_jbr="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  [[ -d "$studio_jbr" ]] && export JAVA_HOME="$studio_jbr"
fi
build_tools=$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/* | sort -V | tail -1)

# 1. Preconditions.
git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null ||
  die "tag $tag is not on origin (push it first)"
gh release view "$tag" >/dev/null 2>&1 && die "release $tag already exists"
[[ "$(git rev-parse HEAD)" == "$(git rev-parse "$tag^{commit}")" ]] ||
  die "HEAD is not at $tag (git checkout $tag first)"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] ||
  die "working tree has uncommitted changes"
pub_version=$(sed -n 's/^version: //p' pubspec.yaml)
[[ "${pub_version%%+*}" == "$version" ]] ||
  die "pubspec.yaml has $pub_version, expected $version"
build_number="${pub_version##*+}"

notes=$(awk -v v="$version" '
  $0 ~ "^## \\[" v "\\]" {on=1; next}
  on && /^## \[/ {exit}
  on {print}' CHANGELOG.md)
[[ -n "${notes//[[:space:]]/}" ]] || die "no CHANGELOG.md section for $version"

# 2. Build and verify.
flutter build apk --release >/dev/null
apk=build/app/outputs/flutter-apk/app-release.apk
badging=$("$build_tools/aapt2" dump badging "$apk" | head -1)
[[ "$badging" == *"versionCode='$build_number'"* && "$badging" == *"versionName='$version'"* ]] ||
  die "APK version mismatch: $badging"
cert=$("$build_tools/apksigner" verify --print-certs "$apk" | sed -n 's/.*SHA-256 digest: //p' | head -1)
[[ "$cert" == "$release_cert" ]] || die "APK is not signed with the release key ($cert)"

out="build/Cratewise-$version.apk"
cp "$apk" "$out"
sha=$(shasum -a 256 "$out" | cut -d' ' -f1)

# 3. Publish.
gh release create "$tag" "$out" --verify-tag --title "Cratewise $version" --notes "$notes

---
**Android:** download \`Cratewise-$version.apk\` and install it (allow installs from this source). It updates an existing Cratewise install.
SHA-256: \`$sha\`"
echo "✓ Released $tag: $(gh release view "$tag" --json url -q .url)"
