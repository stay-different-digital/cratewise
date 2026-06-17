import { HtmlBasePlugin } from "@11ty/eleventy";
import MarkdownIt from "markdown-it";

const md = new MarkdownIt({ html: true, linkify: true });

export default function (eleventyConfig) {
  // Rewrites absolute URLs when the site is served from a path prefix,
  // e.g. GitHub Pages project sites at https://<user>.github.io/Crate/.
  eleventyConfig.addPlugin(HtmlBasePlugin);

  eleventyConfig.addPassthroughCopy("src/css");

  // Render a Markdown string to HTML — used by the Changelog page, whose body
  // comes from the repo-root CHANGELOG.md via the `changelog` global data file.
  eleventyConfig.addFilter("markdown", (value) =>
    value ? md.render(value) : "",
  );

  // Rebuild when the source-of-truth changelog changes during `--serve`.
  eleventyConfig.addWatchTarget("../CHANGELOG.md");

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
