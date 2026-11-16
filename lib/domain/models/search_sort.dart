/// Order of Discogs search results (US-133).
///
/// [relevance] is Discogs' default and sends no sort parameter. The year
/// orders map to `sort=year&sort_order=desc|asc`, which `/database/search`
/// accepts although the public API docs don't list them (verified
/// 2026-11-16, see docs/api/DISCOGS_API.md). Sorting happens server-side so
/// later pages continue the same order.
enum SearchSort { relevance, newestFirst, oldestFirst }
