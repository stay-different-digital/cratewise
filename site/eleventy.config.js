import { HtmlBasePlugin } from "@11ty/eleventy";
import MarkdownIt from "markdown-it";
import markdownItAnchor from "markdown-it-anchor";
import { githubSlug } from "./lib/repo-markdown.js";

// Heading ids use GitHub's slug algorithm so the TOC anchors in README.md
// (e.g. #tech-stack--architecture) resolve on the rendered About page.
const md = new MarkdownIt({ html: true, linkify: true }).use(markdownItAnchor, {
  slugify: githubSlug,
});

export default function (eleventyConfig) {
  // Rewrites absolute URLs when the site is served from a path prefix,
  // e.g. GitHub Pages project sites at https://<user>.github.io/cratewise/.
  eleventyConfig.addPlugin(HtmlBasePlugin);

  eleventyConfig.addPassthroughCopy("src/css");

  // Render a Markdown string to HTML — used by the Changelog and About pages,
  // whose bodies come from the repo-root CHANGELOG.md / README.md via the
  // `changelog` / `readme` global data files.
  eleventyConfig.addFilter("markdown", (value) =>
    value ? md.render(value) : "",
  );

  // Rebuild when the source-of-truth files change during `--serve`.
  eleventyConfig.addWatchTarget("../CHANGELOG.md");
  eleventyConfig.addWatchTarget("../README.md");

  return {
    dir: {
      input: "src",
      output: "_site",
      layouts: "_layouts",
    },
    // Overridden with --pathprefix in CI for GitHub Pages.
    pathPrefix: "/",
  };
}
