-- Ensure the treesitter parsers that `:checkhealth` complains about are
-- always present: noice needs bash+regex, render-markdown/snacks need
-- html+yaml (+css/js/latex family for docs/image queries).
-- One spec serves both flavors: parsers are a few MB, Hatta just gets
-- zero warnings while server stays minimal-but-quiet.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "regex",
        "html",
        "yaml",
        "latex",
        "css",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "scss",
        "svelte",
        "tsx",
        "typescript",
        "typst",
        "vim",
        "vue",
      },
    },
  },
}
