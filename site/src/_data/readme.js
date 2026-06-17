import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { rewriteRepoLinks } from "../../lib/repo-markdown.js";

const here = path.dirname(fileURLToPath(import.meta.url));

// Eleventy global data: the repo-root README.md is the single source of truth
// for the project overview. We read it at build time and rewrite repo-relative
// Markdown links (docs/, source paths, pubspec.yaml, etc.) to absolute GitHub
// URLs so the developer-facing links don't 404 on the public site (see
// lib/repo-markdown.js). The About page renders this through the `markdown`
// filter, so there is no hand-maintained copy to drift.
export default function () {
  const source = path.join(here, "..", "..", "..", "README.md");
  return rewriteRepoLinks(fs.readFileSync(source, "utf8"));
}
