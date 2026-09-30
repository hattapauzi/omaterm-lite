-- lang.markdown (lazyvim.json) wires `markdownlint-cli2` diagnostics through
-- nvim-lint, and the MD0xx noise clutters markdown buffers. Clear the
-- linter list for markdown while keeping the rest of the extra (marksman
-- LSP, formatting, treesitter parsers, rendering).
-- Re-enable by deleting the `linters_by_ft` block below (the custom
-- --config args in markdownlint-cli2.yaml still apply then).
return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
}
