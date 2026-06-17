import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));

// Repo the changelog's repo-relative links should resolve to on the public
// site. Single place to update if the repo is renamed (see US-93).
const REPO_BLOB_BASE = "https://github.com/itris/Crate/blob/master/";

// Eleventy global data: the repo-root CHANGELOG.md is the single source of
// truth. We read it at build time and rewrite repo-relative Markdown links
// (e.g. docs/...) to absolute GitHub URLs so they don't 404 on the Pages site;
// absolute (http/mailto), root-relative (/) and in-page anchor (#) links are
// left untouched. The Changelog page renders this string through the `markdown`
// filter, so there is no hand-maintained on-site copy to drift.
export default function () {
  const source = path.join(here, "..", "..", "..", "CHANGELOG.md");
  const raw = fs.readFileSync(source, "utf8");
  return raw.replace(
    /\]\((?!https?:\/\/|\/|#|mailto:)([^)]+)\)/g,
    (_match, link) => `](${REPO_BLOB_BASE}${link})`,
  );
}
