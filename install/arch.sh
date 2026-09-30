install_packages() {
  local official_pkgs=(
    base-devel git openssh sudo less inetutils whois
    zsh starship fzf fd ripgrep eza zoxide tmux btop man-db
    vim neovim
    clang llvm rust libyaml
    unzip
    python-pip python-virtualenv
    xdg-utils sqlite
    lazygit lazydocker
    docker docker-buildx docker-compose
    tree-sitter-cli
    kitty-terminfo
  )

  section "Installing Arch packages..."
  sudo pacman -Syu --needed --noconfirm "${official_pkgs[@]}"

  # tldr/tealdear: CachyOS ships tealdear which conflicts with tldr
  if ! command -v tldr &>/dev/null && ! command -v tealdear &>/dev/null; then
    if pacman -Si tealdear &>/dev/null; then
      sudo pacman -S --needed --noconfirm tealdear
    else
      sudo pacman -S --needed --noconfirm tldr
    fi
  fi

  # nvim-treesitter needs tree-sitter-cli >= 0.26.1; fall back to the
  # upstream binary when the repo snapshot is older. Guarded so an
  # unresolvable version or failed download warns instead of failing
  # the install under `set -euo pipefail`.
  local ts_v
  ts_v="$(tree-sitter --version 2>/dev/null | grep -Po 'v?\K[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
  if [ -z "$ts_v" ] || [ "$(printf '%s\n' "0.26.1" "$ts_v" | sort -V | head -n1)" != "0.26.1" ]; then
    local TS_ARCH
    case "$(uname -m)" in
    x86_64) TS_ARCH="x64" ;;
    aarch64 | arm64) TS_ARCH="arm64" ;;
    *) TS_ARCH="" ;;
    esac
    if [ -z "$TS_ARCH" ]; then
      echo "⚠ unsupported arch for upstream tree-sitter-cli; parsers fall back to prebuilt"
    else
      local TS_VERSION
      TS_VERSION=$(curl -fsSL "https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*' || true)
      if [ -z "$TS_VERSION" ]; then
        echo "⚠ could not resolve latest tree-sitter-cli; keeping distro version"
      elif ! curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VERSION}/tree-sitter-linux-${TS_ARCH}.gz" 2>/dev/null | gunzip > /tmp/tree-sitter; then
        echo "⚠ upstream tree-sitter-cli download failed; keeping distro version"
      else
        sudo install -m 0755 /tmp/tree-sitter /usr/local/bin/tree-sitter
      fi
      rm -f /tmp/tree-sitter
    fi
  fi
}

if ! command -v yay &>/dev/null; then
  section "Installing yay..."
  local tmpdir
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
fi

install_npm_tools() {
  :
}

enable_services() {
  section "Enabling services..."

  if ! is_systemd; then
    echo "⚠ systemd not running — skipping service enabling"
    return
  fi

  sudo systemctl enable docker.service
  sudo systemctl start --no-block docker.service
  echo "✓ Docker"

  if [ "${OMATERM_PROFILE:-server}" = "server" ]; then
    sudo systemctl enable --now sshd.service
    echo "✓ sshd"
  fi
}
