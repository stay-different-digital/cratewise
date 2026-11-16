# Store Copy — Title & Promotional Text Options

A focused set of **ready-to-paste, character-counted options** for the App
title, subtitle/short description, and promotional text. Pick one of each,
then copy the winner into the corresponding field in
[`STORE_LISTINGS.md`](./STORE_LISTINGS.md) (the source of truth) before filing
the store forms.

Counts shown as `(NN/LIMIT)`. Stores reject anything over the limit, and they
count every space and em-dash.

---

## App title / name

Play "App title" and App Store "App name" share a **30-character** limit, so
keep one title for both. `STORE_LISTINGS.md` currently uses option A.

| # | Title | Count |
|---|---|---|
| A | Cratewise — Vinyl Collection | (28/30) |
| B | Cratewise: Vinyl & Records | (26/30) |
| C | Cratewise — Record Crate | (24/30) |
| D | Cratewise Vinyl Catalogue | (25/30) |

**Recommendation:** A. The keyword "Vinyl Collection" is what people actually
search, and the em-dash reads cleaner than a colon on the store grid.

---

## Android — short description (80 chars)

Shown under the title in Play search results. Punchy, verb-first, no period
needed.

| # | Short description | Count |
|---|---|---|
| A | Catalogue your vinyl: search Discogs, browse labels, track your wantlist. | (73/80) |
| B | Search, sort and catalogue your records. Fully offline, no account needed. | (74/80) |
| C | Your vinyl collection and wantlist in your pocket — search, sort, dig. | (70/80) |

**Recommendation:** A (current, since 1.1.0 without the scanner). It names
Discogs, which collectors recognise, and the label browsing that replaced
scanning as the headline action.

---

## iOS — subtitle (30 chars)

Shown under the app name on the product page and in some search results.

| # | Subtitle | Count |
|---|---|---|
| A | Catalogue & dig your records | (28/30) |
| B | Track your vinyl & wantlist | (27/30) |
| C | Vinyl collection & wantlist | (27/30) |

**Recommendation:** A (current) — cataloguing plus the crate-digging identity;
the old "scan" wording went with the scanner in 1.1.0.

---

## iOS — promotional text (170 chars)

The one field you can update **any time without a new app review** — use it for
the current hook or a seasonal line. Appears above the description.

| # | Promotional text | Count |
|---|---|---|
| A | Your record collection in your pocket: search Discogs for vinyl only, browse every release on a label, and never buy the same pressing twice. | (141/170) |
| B | Dig smarter. Find every vinyl release on a label, newest first, check your wantlist in the shop, and know before you buy. No account, no ads. | (141/170) |
| C | Every record you own and every one you want — in your pocket, fully offline. Search millions of Discogs releases, add in two taps. | (130/170) |
| D | Never buy a double again. See instantly if a release is already in your collection, and keep your wantlist with you everywhere. | (127/170) |

**Recommendation:** A for 1.1.0 (matches `STORE_LISTINGS.md`) — it leads with
this release's new search features. C remains the evergreen fallback; D is the
"problem/solution" hook once you have reviews.

---

## Play — promotional text equivalent

Google Play has **no** separate promo-text field. The hook lives in the **first
two lines of the full description** (the part shown before "read more"). Make
sure the full description in `STORE_LISTINGS.md` opens with its strongest
sentence — currently:

> Cratewise is the fast, focused collection app for vinyl collectors and DJs.

Alternative opener if you want more punch:

> Catalogue your entire record collection and wantlist in your pocket — search
> millions of Discogs releases, vinyl only if you like, fully offline.

---

## Notes

- **Trademark:** keep "Cratewise uses the Discogs API but is not affiliated with
  Discogs." in the long description (already present). Do not put "Discogs" in
  the **title** — store trademark policies frown on it.
- **No fake claims:** don't write "official Discogs app" anywhere.
- Apple **keywords** (100 chars, comma-separated, no spaces) live in
  `STORE_LISTINGS.md`; they are separate from the description and not shown to
  users.
