/// Order of Discogs search results (US-133, changed in US-162).
///
/// [relevance] is Discogs' default and sends no sort parameter. Newest and
/// oldest first order by when the release was added to the Discogs database:
/// `sort=date_added&sort_order=desc|asc`, which `/database/search` accepts
/// although the public API docs don't list it (verified 2026-11-17, see
/// docs/api/DISCOGS_API.md). Sorting happens server-side so later pages
/// continue the same order.
enum SearchSort { relevance, newestFirst, oldestFirst }
