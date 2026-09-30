install_packages() {
  section "Updating system packages..."
  sudo dnf upgrade -y

  section "Installing Fedora packages..."
  sudo dnf install -y @development-tools \
    git openssh-server sudo less net-tools whois \
    zsh fzf fd-find ripgrep zoxide tmux btop man-db tldr \
    vim neovim \
    clang llvm rust cargo libyaml \
    curl wget \
    unzip \
    python3-pip python3-virtualenv \
    xdg-utils sqlite \
    tree-sitter-cli \
    kitty-terminfo

  # starship (not in Fedora repos)
  if ! command -v starship &>/dev/null; then
    section "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # eza (not in Fedora repos)
  if ! command -v eza &>/dev/null; then
    section "Installing eza..."
    cargo install eza
  fi

  # Docker (not in Fedora repos, needs Docker's official repo)
  if ! command -v docker &>/dev/null; then
    section "Installing Docker..."
    sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  # lazygit (via COPR)
  if ! command -v lazygit &>/dev/null; then
    section "Installing lazygit..."
    sudo dnf copr enable -y atim/lazygit
    sudo dnf install -y lazygit
  fi

  # lazydocker (not in repos)
  if ! command -v lazydocker &>/dev/null; then
    section "Installing lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
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
