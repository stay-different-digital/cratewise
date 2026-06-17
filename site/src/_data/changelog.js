import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { rewriteRepoLinks } from "../../lib/repo-markdown.js";

const here = path.dirname(fileURLToPath(import.meta.url));

// Eleventy global data: the repo-root CHANGELOG.md is the single source of
// truth. We read it at build time and rewrite repo-relative Markdown links to
// absolute GitHub URLs (see lib/repo-markdown.js). The Changelog page renders
// this string through the `markdown` filter, so there is no hand-maintained
// on-site copy to drift.
export default function () {
  const source = path.join(here, "..", "..", "..", "CHANGELOG.md");
  return rewriteRepoLinks(fs.readFileSync(source, "utf8"));
}
