## Prompt 5H: Add thumbnail cache abstraction

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: add a thumbnail cache abstraction.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Add a small thumbnail cache service or repository.
* The cache should support saving and reading cover thumbnails where possible.
* The cache should use local app storage.
* Do not connect the thumbnail cache to UI yet.
* Do not download all images in bulk.
* Do not add background sync.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Cache can store a thumbnail by release ID or image URL key.
* Cache can return a local thumbnail path or bytes if available.
* Cache handles failed downloads safely.
* Cache avoids crashing when image URL is missing.
* Cache does not store tokens.
* Cache does not log tokens.

Acceptance criteria:

* Thumbnail cache abstraction exists.
* Thumbnail cache implementation exists.
* Thumbnail can be stored where possible.
* Thumbnail can be loaded where possible.
* Failed thumbnail download is handled safely.
* No UI behavior changes.
* No bulk image download is added.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Main cache choices
* Tests/checks run
* Known limitations
* Recommended next small task