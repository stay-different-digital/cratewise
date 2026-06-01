## Prompt 5F: Cache release metadata after loading release detail

Read AGENTS.md and the docs in docs/product, docs/architecture, docs/design, docs/api, docs/security, and docs/workflow.

Implement the next small Phase 5 feature slice for Cratewise: save release detail metadata to the local metadata cache after loading from Discogs.

Scope:

* Keep the existing Flutter app runnable.
* Keep support for Android, iPhone, and iPad.
* Use the existing Release Detail screen.
* Use the existing Discogs release detail API method.
* Use the existing cached release metadata repository.
* When release details load successfully from Discogs, save the metadata locally.
* Do not change how release details are displayed yet.
* Do not add offline fallback yet.
* Do not add thumbnail caching yet.
* Do not add sync status UI yet.
* Do not add retry behavior yet.
* Do not add cloud sync.
* Do not hardcode secrets.
* Do not log tokens.

Functional requirements:

* Successful release detail API response is saved to local cache.
* Cache save failure should not break the release detail screen.
* Cache save failure should be handled safely.
* Token must never be cached, shown, or logged.

Acceptance criteria:

* Release metadata is cached after successful detail load.
* Release Detail screen still behaves as before.
* Cache save failure does not crash the app.
* No offline fallback is added yet.
* No token is cached.
* No token is logged.
* `flutter analyze` passes.
* `flutter test` passes.
* `flutter build apk --debug` passes.
* `flutter build ios --debug --no-codesign` passes if available.

After implementation, summarize:

* Files changed
* Tests/checks run
* Known limitations
* Recommended next small task
