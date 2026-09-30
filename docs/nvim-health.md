# Neovim `:checkhealth` policy

Two flavours, two bars.

## Server (`lite`) — minimal, quiet by design

Goal: no **actionable** warnings, zero heavy toolchains.

| Area | State |
|---|---|
| `lazyvim`/`snacks.picker` `fd` | installed (`fd-find` + `fd` symlink on Debian/Ubuntu) |
| `mason` `pip` | installed (`python3-pip` + `python3-venv`) |
| `noice`/`snacks`/`render-markdown` parsers | pre-declared in `config/nvim/lua/plugins/treesitter.lua` (`bash,regex,html,yaml,…`), auto-installed on first launch |
| `tree-sitter-cli` | installer enforces `>= 0.26.1` on all distros (`install/debian.sh`, `install/arch.sh`, `install/fedora.sh`), falls back to upstream binary with warn-instead-of-fail guards |
| `vim.provider` (node/perl/python3/ruby) | disabled in `config/nvim/lua/config/options.lua` when flavour ≠ `hatta` — unused on server |
| `lazy` `rocks` | enabled only when flavour = `hatta` (`config/nvim/lua/config/lazy.lua`) — no plugin needs it on server |
| stale `site/pack/core` | removed on every install (`install.sh`; single site, not duplicated) |
| `vim.ui.open` | `xdg-utils` installed |

Deliberately **ignored** on server: `conform` non-shell formatters
(`prettier`, `markdownlint-cli2`, `markdown-toc`, `fish_indent`),
`grug-far` `ast-grep`, `mason` Go/Java/Ruby/Julia/cargo languages,
image/PDF/LaTeX/Mermaid stack (`magick`, `gs`, `tectonic`, `mmdc`),
`sqlite` frecency fallback, `gio` trash fallback.

## Hatta (`desktop`) — full green, heavy on purpose

`install/hatta.sh` (runs only when `OMATERM_FLAVOR=hatta`, after configs so
the headless warm-up sees `~/.config/nvim`) installs everything health
checks for:

- languages: `fish`, `golang-go`, `cargo` (Debian keeps server base at `rustc`-only), `nodejs`+`npm`, `luarocks`, `ruby`, `default-jdk`, `julia` (best-effort), `perl`+`cpanminus`
- providers/bridges: npm `neovim`, pip `pynvim`, gem `neovim`, `cpanm` `Neovim::Ext` (cpanm-only; interactive `cpan` is never invoked)
- formatters/linters: npm `prettier`, `markdownlint-cli2`, `markdown-toc`; pip `latex2text`/`pylatexenc`
- docs/media: `imagemagick`, `ghostscript`, `tectonic` (or `pdflatex` fallback; cargo builds time-boxed at 15 min), npm `@mermaid-js/mermaid-cli` (`mmdc`), `ast-grep`/`sg`
- desktop integration: `gvfs`, `wl-clipboard`, `sqlite3`, Hack Nerd Font
- warm-up: `Lazy! sync` + `TSUpdateSync` headless (best-effort, never fails install)

Providers and rocks are flavour-gated in the nvim config, so Hatta is
functional out of the box: `options.lua` skips the `loaded_*_provider = 0`
disables and `lazy.lua` enables `rocks` when `~/.config/omaterm/flavor`
reads `hatta`.

## Cannot be green (both flavours, do not chase)

These are informational or conflict with LazyVim defaults:

- `blink.cmp`: "Some providers show as disabled but are enabled dynamically" — by design.
- `which-key`: overlapping `<gc>/<a>/<i>/<o>` maps — explicitly "for informational purposes only".
- `snacks`: `dashboard did not open (argc>0)` (transient), `explorer/image/scroll/statuscolumn disabled` (we disable scroll animations in `plugins/snacks-animated-scrolling.lua`; image needs a Kitty-compatible terminal).
- `snacks.image`: `kitty/wezterm/ghostty` detection over `tmux+ssh` — terminal-dependent, not installable.
- `vim.pack`: lockfile warning if you mix `vim.pack` with `lazy` — we use `lazy` only.
- `vim.health`: `Nvim x.y.z available` — update on next installer run.
