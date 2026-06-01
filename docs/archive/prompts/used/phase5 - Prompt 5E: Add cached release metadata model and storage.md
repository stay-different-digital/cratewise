## Prompt 5E: Add cached release metadata model and storage

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add local cached release metadata storage.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a CachedReleaseMetadata model.
* Add a repository interface for cached release metadata.
* Add a local storage implementation for cached release metadata.
* Do not connect this cache to the Release Detail screen yet.
* Do not connect this cache to Search yet.
* Do not add thumbnail caching yet.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not hardcode secrets.
* Do not log tokens.

Cached metadata should support:

* Discogs release ID
* Artist
* Title
* Label if available
* Catalog number if available
* Format if available
* Country if available
* Year if available
* Genre if available
* Style if available
* Tracklist if available
* Notes if available
* Barcode and identifiers if available
* Cover image URL if available
* Last fetched date
* Cache source
* Sync status if useful

Acceptance criteria:

* CachedReleaseMetadata model exists.
* Cached release metadata repository interface exists.
* Local cache storage implementation exists.
* Cached metadata can be saved.
* Cached metadata can be loaded by Discogs release ID.
* No UI behavior changes.
* No API behavior changes.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main cache model choices
* Tests/checks run
* Known limitations
* Recommended next small task