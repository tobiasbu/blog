const path = require("path")
const Nunjucks = require("nunjucks");

const SRC_DIR = __dirname;
const INPUT_DIR = `${SRC_DIR}/pages`;

module.exports = function (eleventyConfig) {
  eleventyConfig.addWatchTarget("css");
  eleventyConfig.addWatchTarget("posts");

  // add posts collection
  eleventyConfig.addCollection("posts", function(collection) {
    return collection.getFilteredByGlob("./posts/**/*.md");
  });

  // disables layout resolution to improve build performance
  eleventyConfig.setLayoutResolution(false);

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


  return {
    dir: {
      input: ".",
      output: "_site",
      includes: 'includes',
      layouts: "layouts",
      htmlTemplateEngine: "njk",
      markdownTemplateEngine: "njk"
    }
  }
} 