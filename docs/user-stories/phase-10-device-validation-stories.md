# Phase 10 Device Validation — User Stories

Derived from findings in `docs/qa/PHASE_10_DEVICE_VALIDATION.md`.
**Beta importance:** M = consider fixing before beta, S = defer to post-beta
**Story points** are estimates for a single developer.

---

### US-53: App always opens on the Search tab after a cold start

**Beta: M · 3 SP**

> As a user opening the app,
> I want it to always start on the Search tab,
> so that every session begins from a predictable home screen instead of a random tab.

**Acceptance criteria:**
- A cold start (process killed, then relaunched) always shows the Search tab, on Android, iPhone, and iPad.
- Ten consecutive kill-and-relaunch cycles all land on the Search tab with the Search destination shown as selected in the navigation bar.
- The navigation bar selection indicator does not animate in from a different tab on startup.
- The root cause of the observed drift is identified and documented (during QA, consecutive simulator relaunches landed on Wishlist, then Scan, then Settings, even though `router.dart` sets `initialLocation: AppRoutes.search` and no restoration scope is configured).
- A regression test covers the initial route: building the app fresh shows the Search screen as the active branch.
- Verified on at least one physical device in addition to the simulator, since the behaviour was only observed on the iOS simulator so far.

**Found during:** Phase 10 device validation, iPhone 17 Pro simulator (iOS 26), finding #2.

**Investigation notes:**
- Observed sequence across cold starts: Wishlist → Scan → Settings → Settings (sticky); evidence in `/tmp/qa_a11_relaunch.png` and `/tmp/qa_relaunch3.png`.
- `GoRouter` is created as a top-level/global instance — if it (or `StatefulShellRoute`) preserves state across engine restarts in some configuration, or if the launch sequence replays a navigation event, that could explain the drift. Check whether the router instance is rebuilt per `runApp` and whether `StatefulShellRoute.indexedStack` restores a stale branch index.
- The drive test ended its session on the Settings tab; the drift pattern suggests something replays or restores prior-session navigation rather than randomness.
