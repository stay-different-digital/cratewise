# Cratewise Beta — Tester Guide

Thanks for testing Cratewise! This page tells you how to get set up, what to
try, and how to report anything weird. Fifteen minutes of focused poking
helps more than an hour of polite browsing.

## Getting set up

1. **Install the beta**
   - **Android:** open the internal-testing invite link on your phone and
     install via the Play Store.
   - **iPhone / iPad:** install **TestFlight** from the App Store, then open
     the invite link.
2. **Connect Discogs (recommended)** — Cratewise works without an account,
   but the good parts use the Discogs database.
   - Use **your own** Discogs account.
   - In Cratewise: Settings → paste a personal access token → Validate. The
     "Find your token at discogs.com/settings/developers" link takes you to
     where tokens are created.
   - Your token stays on your device; treat it like a password and don't
     share it with anyone (including in feedback emails).

## What to try

In rough priority order — real-world usage beats checklist clicking:

1. **Dig like you're in a record store.** Search for records you actually own
   or want. Check pressings, tracklists, identifiers. Anything wrong or slow?
2. **Scan barcodes** — including awkward ones: curved shrink wrap, bad
   lighting, small 7" sleeves. Try the flashlight toggle.
3. **Build your collection.** Add records, grade conditions, write notes,
   add tags and storage locations. Edit and remove. Does everything stick
   after force-closing the app?
4. **Use the wantlist.** Add wants, set priorities and target prices. Stand
   in a shop and check whether you already own something before buying it.
5. **Import and export.** Import your existing Discogs collection and
   wantlist. Export to CSV and open the file. Push local items to Discogs and
   confirm they appear on discogs.com.
6. **Go offline.** Airplane mode: browse your collection, open a record you
   viewed before. Does the app behave sensibly without internet?
7. **iPad people:** rotate to landscape, use Split View next to Safari or
   Discogs, and check that layouts use the space sensibly.

## Reporting problems

Use **Settings → Send feedback** in the app — it opens an email with your
app version already filled in. Add:

- **Your device** (e.g. Pixel 8, iPhone 15 Pro, iPad Air 11")
- **What you did** — steps, as specific as you can
- **What you expected**, and **what actually happened**
- **Screenshots** if it's visual

One issue per email is perfect. "Search feels slow" is useful; "search for
'Aphex Twin' takes ~10s on hotel wifi" is gold.

## Known limitations in this beta

- English-only UI.
- Discogs connection requires a personal access token — there is no
  "Log in with Discogs" button yet.
- No automatic sync; import/export is manual and on-demand.
- Collection export to Discogs sets folder and wantlist items with default
  settings (no per-item folder/notes mapping yet).
