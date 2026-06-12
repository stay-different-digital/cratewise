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

---

### US-54: Token helper text wraps instead of truncating on narrow screens

**Beta: S · 1 SP**

> As a user setting up my Discogs token on a phone,
> I want the helper text under the token field to be fully readable,
> so that I know the expected token format without guessing at a cut-off sentence.

**Acceptance criteria:**
- The helper text "Discogs personal access tokens are 40 characters" wraps onto multiple lines when it does not fit on one line, instead of truncating with an ellipsis ("…are 40 char…").
- The full text is readable on the narrowest supported phone width, in both portrait and landscape.
- The character counter (`0/40`) remains visible and correctly positioned next to or below the wrapped helper text.
- Wrapping does not overlap or push the token field, the help link, or the buttons out of alignment.
- Still readable at the largest system text size (accessibility text scaling).
- A widget test asserts the helper text is not truncated (e.g. `helperMaxLines` is set, or equivalent).

**Found during:** Phase 10 device validation, iPhone 17 Pro simulator (iOS 26), finding #3.

**Implementation note:** the token `TextField` in
`lib/presentation/widgets/discogs_token_section.dart` uses `helperText` in its
`InputDecoration`; Flutter truncates helper text to one line unless
`helperMaxLines` (e.g. `2`–`3`) is set.

---

### US-55: No unexpected glyph in the search bar in dark mode

**Beta: S · 1 SP**

> As a user in dark mode with no query entered,
> I want the search bar to show only the search icon on the left,
> so that the bar looks clean and intentional in both light and dark mode.

**Acceptance criteria:**
- With no query entered, the search bar shows the search icon (prefix) and no suffix icon in both light and dark mode.
- The glyph observed at the right end of the search bar in dark mode during QA is identified, explained, and either removed or intentionally replaced with a correctly styled widget.
- A widget test asserts that no suffix icon is rendered when the query field is empty, in both light and dark theme.

**Found during:** Phase 10 device validation, iPhone 17 Pro simulator (iOS 26), finding #4.

**Investigation notes:**
- Screenshot: `/tmp/qa_a3_dark.png`. The glyph appears at the right end of the search bar with no query text entered (so it is not the clear button, which is only shown when `hasQuery` is true).
- The `SearchScreen` `TextField` sets `suffixIcon: hasQuery ? IconButton(Icons.clear, …) : null`. With no query, suffix is explicitly `null` — Flutter's `InputDecoration` should render nothing there.
- Hypothesis: iOS renders a platform-level dictation/microphone button as a keyboard accessory that bleeds into the text field's suffix area under certain dark-mode contrast conditions. The `TextField` does not set `keyboardType`, so it defaults to `TextInputType.text` which allows dictation on iOS.
