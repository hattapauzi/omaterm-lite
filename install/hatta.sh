#!/usr/bin/env bash
# Hatta (desktop) extras: everything `:checkhealth` warns about, installed
# so Hatta flavour is green. Server (lite) never sources this file and
# stays minimal on purpose.
#
# Design: per-OS system packages first, then language bridges (npm/pip/gem/
# cpan) and doc/media binaries shared across distros. Every heavy step is
# best-effort-guarded where the upstream package may not exist on older
# releases (julia, tectonic) so one missing optional dep never fails install.

install_hatta_deps_debian() {
  section "Installing Hatta extras (Debian)..."
  apt_get install -y \
    fish \
    golang-go cargo \
    nodejs npm \
    luarocks \
    ruby ruby-dev \
    default-jdk \
    perl cpanminus \
    imagemagick ghostscript \
    gvfs wl-clipboard \
    fontconfig || true
  # julia is universe-only on some Ubuntu releases; ignore if absent.
  apt_get install -y julia 2>/dev/null || echo "⚠ julia not in apt repos — skipping (mason julia warning stays)"
  # rustc + pip/venv + fd + sqlite already come from install_packages.
}

install_hatta_deps_arch() {
  section "Installing Hatta extras (Arch)..."
  sudo pacman -S --needed --noconfirm \
    fish go nodejs npm luarocks ruby jdk-openjdk julia \
    perl cpanminus \
    imagemagick ghostscript tectonic \
    gvfs wl-clipboard sqlite \
    fontconfig 2>/dev/null || \
  sudo pacman -S --needed --noconfirm \
    fish go nodejs npm luarocks ruby jdk-openjdk \
    perl imagemagick ghostscript \
    gvfs wl-clipboard fontconfig || true
  # ast-grep lives in extra; fall back to cargo in the media stack below.
  sudo pacman -S --needed --noconfirm ast-grep 2>/dev/null || true
}

install_hatta_deps_fedora() {
  section "Installing Hatta extras (Fedora)..."
  sudo dnf install -y \
    fish golang nodejs npm luarocks ruby ruby-devel \
    java-21-openjdk-devel \
    julia \
    perl perl-App-cpanminus \
    ImageMagick ghostscript tectonic \
    gvfs wl-clipboard sqlite fontconfig 2>/dev/null || \
  sudo dnf install -y \
    fish golang nodejs npm luarocks ruby \
    java-21-openjdk-devel \
    perl perl-App-cpanminus \
    ImageMagick ghostscript \
    gvfs wl-clipboard sqlite fontconfig || true
  sudo dnf install -y ast-grep 2>/dev/null || true
}

# Shared: npm/pip/gem/cpan bridges for vim.provider + conform formatters +
# render-markdown latex text + mermaid. Requires node/python/ruby from base.
install_hatta_nvim_bridges() {
  section "Installing Hatta Neovim bridges..."

  # npm: neovim (provider) + prettier/markdownlint/markdown-toc (conform +
  # nvim-lint) + mermaid-cli (mmdc for snacks image diagrams).
  # nodejs+npm come from install_hatta_deps_*; warn (don't fail) if absent.
  if command -v npm &>/dev/null; then
    sudo npm install -g --no-fund --no-audit \
      neovim prettier markdownlint-cli2 markdown-toc \
      @mermaid-js/mermaid-cli 2>/dev/null || \
    npm install -g --no-fund --no-audit \
      neovim prettier markdownlint-cli2 markdown-toc \
      @mermaid-js/mermaid-cli || true
  else
    echo "⚠ npm not found — skipping node bridges (provider/formatter warnings stay)"
  fi

  # pip: pynvim (provider) + latex2text/pylatexenc (render-markdown latex).
  if command -v pip3 &>/dev/null; then
    pip3 install --user --break-system-packages \
      pynvim latex2text pylatexenc 2>/dev/null || \
    pip3 install --user pynvim 2>/dev/null || true
  fi

  # gem: neovim (provider).
  if command -v gem &>/dev/null; then
    sudo gem install --no-document neovim 2>/dev/null || \
      gem install --user-install --no-document neovim 2>/dev/null || true
  fi

  # cpan: Neovim::Ext (provider) via cpanm only — the interactive `cpan`
  # first-run configurator can hang, so it is never invoked here.
  if command -v cpanm &>/dev/null; then
    sudo cpanm -n Neovim::Ext 2>/dev/null || echo "⚠ cpanm Neovim::Ext failed — perl provider warning stays"
  else
    echo "⚠ cpanm not found — skipping perl bridge (perl provider warning stays)"
  fi
}

# Shared: ast-grep + tectonic binaries when the distro package was missing.
install_hatta_media_stack() {
  export PATH="$HOME/.cargo/bin:$PATH"
  # ast-grep (grug-far extended capabilities).
  if ! command -v ast-grep &>/dev/null && ! command -v sg &>/dev/null; then
    section "Installing ast-grep..."
    if command -v cargo &>/dev/null && command -v timeout &>/dev/null; then
      timeout 900 cargo install --locked ast-grep 2>/dev/null || echo "⚠ cargo ast-grep timed out/failed — trying upstream binary"
    elif command -v cargo &>/dev/null; then
      cargo install --locked ast-grep 2>/dev/null || true
    fi
    if ! command -v ast-grep &>/dev/null && ! command -v sg &>/dev/null; then
      local AG_ARCH AG_VERSION
      AG_ARCH="$(uname -m)"
      case "$AG_ARCH" in
      x86_64) AG_ARCH="x86_64" ;; aarch64 | arm64) AG_ARCH="aarch64" ;;
      *) AG_ARCH="" ;;
      esac
      if [ -n "$AG_ARCH" ]; then
        AG_VERSION=$(curl -fsSL "https://api.github.com/repos/ast-grep/ast-grep/releases/latest" | grep -Po '"tag_name": *"\K[^"]*' || true)
        if [ -n "$AG_VERSION" ]; then
          curl -fsSL "https://github.com/ast-grep/ast-grep/releases/download/${AG_VERSION}/app-${AG_ARCH}-unknown-linux-gnu.zip" -o /tmp/ast-grep.zip 2>/dev/null && \
            sudo unzip -o -j /tmp/ast-grep.zip '*/sg' -d /usr/local/bin 2>/dev/null && \
            sudo chmod 0755 /usr/local/bin/sg 2>/dev/null || true
          rm -f /tmp/ast-grep.zip
        fi
      fi
    fi
  fi

  # tectonic (snacks LaTeX math) when distro package was missing.
  # cargo compile takes minutes; bound it so install stays best-effort.
  if ! command -v tectonic &>/dev/null && ! command -v pdflatex &>/dev/null; then
    section "Installing tectonic..."
    if command -v cargo &>/dev/null && command -v timeout &>/dev/null; then
      timeout 900 cargo install --locked tectonic 2>/dev/null || echo "⚠ cargo tectonic timed out/failed — install texlive manually if needed"
    elif command -v cargo &>/dev/null; then
      cargo install --locked tectonic 2>/dev/null || true
    fi
  fi

  # cargo installs to ~/.cargo/bin, which is not on PATH for GUI/ssh
  # shells by default. Expose the binaries system-wide when present.
  for tool in ast-grep sg tectonic; do
    if ! command -v "$tool" &>/dev/null && [ -x "$HOME/.cargo/bin/$tool" ]; then
      sudo ln -sfn "$HOME/.cargo/bin/$tool" "/usr/local/bin/$tool" 2>/dev/null || true
    fi
  done
  hash -r 2>/dev/null || true
}

# Shared: Nerd Font for the Hatta p10k prompt (check_nerdfont gate).
install_hatta_nerdfont() {
  if command -v fc-list &>/dev/null && fc-list 2>/dev/null | grep -qi nerd; then
    return
  fi
  section "Installing Hack Nerd Font (Hatta)..."
  mkdir -p "$HOME/.local/share/fonts"
  if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip" -o /tmp/hack-nerd.zip 2>/dev/null; then
    unzip -o /tmp/hack-nerd.zip -d "$HOME/.local/share/fonts" 2>/dev/null || true
    rm -f /tmp/hack-nerd.zip
    fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
  else
    echo "⚠ Nerd Font download failed — install one manually (see check_nerdfont)"
  fi
}

install_hatta_extras() {
  local os_id="$1"
  case "$os_id" in
  debian) install_hatta_deps_debian ;;
  arch) install_hatta_deps_arch ;;
  fedora) install_hatta_deps_fedora ;;
  esac
  install_hatta_nvim_bridges
  install_hatta_media_stack
  install_hatta_nerdfont

  # NOTE: stale `site/pack/core` cleanup lives in install.sh (runs before
  # these extras), so it is intentionally not duplicated here.

  # Best-effort headless warm-up so the Docker image ships with parsers
  # and Mason tools prebuilt. Never fails the install (no network in CI
  # still leaves a working setup; LazyVim finishes on first launch).
  if command -v nvim &>/dev/null; then
    section "Warming Neovim plugins/parsers (best-effort)..."
    timeout 300 nvim --headless +"Lazy! sync" +qa 2>/dev/null || true
    timeout 300 nvim --headless +"TSUpdateSync" +qa 2>/dev/null || true
  fi
}
