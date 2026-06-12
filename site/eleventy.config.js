import { HtmlBasePlugin } from "@11ty/eleventy";

export default function (eleventyConfig) {
  // Rewrites absolute URLs when the site is served from a path prefix,
  // e.g. GitHub Pages project sites at https://<user>.github.io/Crate/.
  eleventyConfig.addPlugin(HtmlBasePlugin);

  eleventyConfig.addPassthroughCopy("src/css");

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
