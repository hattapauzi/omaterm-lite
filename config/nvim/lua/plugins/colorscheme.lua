-- Ship every theme plugin but start on `base16-default-dark`.
-- LazyVim applies `opts.colorscheme` on startup, so this single override
-- beats its tokyonight default without uninstalling anything
-- (`:colorscheme default` etc. still work on demand).
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "base16-default-dark",
    },
  },
}
