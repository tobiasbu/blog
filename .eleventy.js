const fs = require("fs");
const path = require("path");

const postcss = require("postcss");
const atImport = require("postcss-import")
const autoprefixer = require("autoprefixer");

const SRC_DIR = __dirname;
const OUT_DIR = `${SRC_DIR}/_site`;
const IS_DEV = process.env.NODE_ENV === "development"

/** @typedef {import("@11ty/eleventy").UserConfig} UserConfig */
/** @param {UserConfig} eleventyConfig */
module.exports = function (eleventyConfig) {
  // disables layout resolution to improve build performance
  eleventyConfig.setLayoutResolution(false);

  // watch folders
  eleventyConfig.addWatchTarget("css");
  eleventyConfig.addWatchTarget("posts");

  // add posts collection
  eleventyConfig.addCollection("posts", function (collection) {
    return collection.getFilteredByGlob("./posts/**/*.md");
  });

  // Filters
  // Relative path
  eleventyConfig.addFilter(
    "relative",
    (page) => {
      let relative = path.relative(path.dirname(page.outputPath), OUT_DIR);
      if (relative.length === 0) {
        return "./"
      }
      return `${relative}/`
    }
  );


  // adds filter for human dates
  eleventyConfig.addFilter("html_date", dateObj => {
    const date = new Date(dateObj);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours() + 1).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day} ${hour}:${minute}`;
  });

  // adds filter for HTML tag <time datetime="..." /> 
  eleventyConfig.addFilter("readable_date", dateObj => {
    const date = new Date(dateObj);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');

    return `${year}-${month}-${day}`;
  });

  // PostCSS
  // Run PostCSS (insert css to html later)
  // Source https://equk.co.uk/2023/06/29/11ty-postcss-integration-optimized/
  eleventyConfig.on('eleventy.before', async () => {
    const cssInputDir = `${SRC_DIR}/css/main.css`
    const cssInput = fs.readFileSync(cssInputDir, {
      encoding: 'utf-8',
    })
    const cssOutDir = `${OUT_DIR}/`
    const cssOutFile = 'styles.css'
    const cssOutput = cssOutDir + cssOutFile
    if (!fs.existsSync(cssOutDir)) {
      fs.mkdirSync(cssOutDir, { recursive: true })
    }
    const minified = await postcss([autoprefixer()])
      .use(atImport())
      .process(cssInput, { from: cssInputDir })
      .then((r) => {
        fs.writeFile(cssOutput, r.css, (err) => {
          if (err) throw err
          console.log(`[11ty] Writing PostCSS Output: ${cssOutput}`)
        })
      })
    return minified
  })

  // PostCSS transform
  //  eleventyConfig.addTransform('postcss', function (content) {
  //   if (this.page.outputPath && this.page.outputPath.endsWith('.html')) {
  //     const minCSS = fs.readFileSync('src/_assets/css/styles.css', {
  //       encoding: 'utf-8',
  //     })
  //     content = content.replace('</head>', `<style>${minCSS}</style></head>`)
  //   }
  //   return content
  // })

  return {
    pathPrefix: IS_DEV ? "" : "/blog/",
    dir: {
      input: ".",
      output: OUT_DIR,
      includes: 'includes',
      layouts: "layouts",
      data: "data",
      htmlTemplateEngine: "njk",
      markdownTemplateEngine: "njk", 
    },
  }
} 