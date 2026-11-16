# Store Listings — Cratewise

Draft content for the Play Console and App Store Connect. Copy-paste into the
consoles; keep this file as the source of truth.

**Privacy policy URL:** `https://itris.github.io/cratewise/privacy/` — served by
the 11ty site in `site/`, deployed by `.github/workflows/deploy-pages.yml`.
_Goes live once GitHub Pages is enabled (repo Settings → Pages → Source:
"GitHub Actions") and the workflow has run; verify the URL before filing
either store form._

**Contact email:** hellowerecratewise@gmail.com

---

## Shared description (long)

> Cratewise is the fast, focused collection app for vinyl collectors and DJs.
>
> Keep your entire record collection and wantlist in your pocket — fully
> offline, always available, no account required.
>
> **Search millions of releases.** Find any pressing, edition, or repress in
> the Discogs database, the world's largest music catalogue, and add it to
> your collection or wantlist in two taps. Show vinyl only, sort newest or
> oldest first, and jump from any release to everything on its label.
>
> **Know your collection.** Statistics by decade, format, genre and style are
> one tap away, and you can filter your collection down to vinyl only.
>
> **Your data, your device.** Everything is stored locally. No ads, no
> tracking, no analytics. Connect your own Discogs account with a personal
> access token to sync your collection and wantlist — or don't, and use
> Cratewise fully standalone.
>
> **Built for crate diggers.** Check your wantlist in the record store,
> confirm whether you already own a pressing before buying it twice, and
> export your collection to CSV whenever you want — your data is never locked
> in.
>
> Cratewise uses the Discogs API but is not affiliated with Discogs.

---

## Android — Play Console

| Field | Value | Limit |
|---|---|---|
| App title | Cratewise — Vinyl Collection | 30 chars |
| Short description | Catalogue your vinyl: search Discogs, browse labels, track your wantlist. | 80 chars |
| Full description | Shared description above | 4000 chars |
| Category | Music & Audio |
| Tags | music, collection, vinyl |
| Contact email | hellowerecratewise@gmail.com |
| Privacy policy URL | _TODO (see top)_ |

### Data safety form (answers match `PRIVACY_POLICY.md`)

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | N/A (nothing collected; Discogs calls are HTTPS) |
| Do you provide a way for users to request that their data is deleted? | N/A (nothing collected; local data removed on uninstall) |

Rationale if Google asks for clarification: the app stores all user data
on-device; the only network traffic is user-initiated HTTPS calls to the
Discogs API authenticated with the user's own token. The developer operates
no server and receives no data. The Discogs token is entered by the user and
stored in Android Keystore-backed secure storage; it is user-provided
credential material for a third-party service, not data collected by the
developer.

Permissions: internet only (Discogs API). The app requests no camera,
location, contacts or other sensitive permissions.

### Screenshot shot-list (Android)

Required: phone (16:9 or 9:16, min 320px, max 3840px), 7" tablet, 10" tablet.
At least 2, up to 8 per form factor. Capture in light mode, seeded with a
realistic collection (~30 records with cover art):

1. Search — results for a well-known record.
2. Collection — grid/list with cover art.
3. Release detail — full release info, label link visible.
4. Label search — a label's releases, newest first, vinyl only.
5. Statistics tab.
6. Wantlist.
7. Settings — Discogs connected state (token obscured — **never show a real
   token**).

---

## iOS — App Store Connect

| Field | Value | Limit |
|---|---|---|
| App name | Cratewise — Vinyl Collection | 30 chars |
| Subtitle | Catalogue & dig your records | 30 chars |
| Promotional text | Your record collection in your pocket: search Discogs for vinyl only, browse every release on a label, and never buy the same pressing twice. | 170 chars |
| Description | Shared description above |
| Keywords | vinyl,records,discogs,collection,crate,wantlist,label,lp,dj,music,statistics | 100 chars |
| Category | Music (primary), Utilities (secondary) |
| Support URL | _TODO — can be the GitHub repo or cratewise.app_ |
| Privacy policy URL | _TODO (see top)_ |

### Privacy nutrition labels (App Privacy section)

Answer: **Data Not Collected.**

For every category (contact info, identifiers, usage data, diagnostics,
user content, etc.): not collected. Rationale: all user data is stored
on-device; no analytics, ads, or crash reporting SDKs; the developer operates
no server. User-initiated Discogs API calls are made directly from the device
with the user's own token and are not "collection" by the developer under
Apple's definition (data must be sent off-device to the developer or partners
to count).

### Export compliance

Cratewise uses only standard HTTPS (ATS) for the Discogs API and platform
secure storage — exempt under category 5A992.c / "uses standard encryption
only". Answer "Yes" to using encryption, "Yes" to exempt. Set
`ITSAppUsesNonExemptEncryption = NO` in `ios/Runner/Info.plist` to skip the
question per build.

### Screenshot shot-list (iOS)

Required sizes: 6.9" iPhone (1320×2868) and 13" iPad (2064×2752). Apple
scales down for smaller devices. Same seven scenes as Android, plus:

8. iPad landscape — demonstrating the tablet layout.
9. iPad Split View — Cratewise side-by-side with another app (iPad
   multitasking is a first-class scenario for in-store wantlist checks).
