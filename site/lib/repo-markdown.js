// Shared helpers for publishing repo-root Markdown (CHANGELOG.md, README.md) on
// the site. Repo-relative links are rewritten to absolute GitHub URLs so they
// don't 404 under the GitHub Pages path prefix.

// The repo the rewritten links resolve to. Single place to update if the repo
// is renamed (see US-93).
export const REPO_BLOB_BASE = "https://github.com/itris/Crate/blob/master/";

// Rewrite repo-relative Markdown links (e.g. docs/...) to absolute GitHub URLs.
// Absolute (http/mailto), root-relative (/) and in-page anchor (#) links are
// left untouched.
export function rewriteRepoLinks(raw) {
  return raw.replace(
    /\]\((?!https?:\/\/|\/|#|mailto:)([^)]+)\)/g,
    (_match, link) => `](${REPO_BLOB_BASE}${link})`,
  );
}

// Heading-id slug matching GitHub's algorithm, so in-page TOC anchors written
// GitHub-style (e.g. #tech-stack--architecture) resolve on the rendered page:
// lowercase, drop characters that aren't word chars / spaces / hyphens, then
// turn runs of spaces into hyphens.
export function githubSlug(text) {
  return String(text)
    .trim()
    .toLowerCase()
    .replace(/[^\w\- ]+/g, "")
    .replace(/ /g, "-");
}
