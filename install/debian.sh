install_packages() {
  local DEB_ARCH BINARY_ARCH
  DEB_ARCH="$(dpkg --print-architecture)"
  case "$DEB_ARCH" in
  amd64) BINARY_ARCH="x86_64" ;;
  arm64) BINARY_ARCH="arm64" ;;
  *)
    echo "Unsupported architecture: $DEB_ARCH"
    return 1
    ;;
  esac
  section "Updating system packages..."
  sudo apt-get update
  sudo apt-get upgrade -y

  section "Installing Debian packages..."
  sudo apt-get remove -y containerd.io 2>/dev/null || true
  sudo apt-get install -y \
    build-essential git openssh-server libssl-dev sudo less net-tools whois \
    zsh fzf ripgrep eza zoxide tmux btop man-db \
    vim \
    clang llvm rustc libyaml-0-2 \
    curl wget gpg \
    docker.io docker-compose \
    kitty-terminfo

  # Neovim from Debian/Ubuntu repos is too old for LazyVim. Use the official stable build when needed.
  local NVIM_BIN
  if ! NVIM_BIN="$(type -P nvim)" || ! dpkg --compare-versions "$($NVIM_BIN --version | awk 'NR == 1 { sub(/^v/, "", $2); print $2 }')" ge "0.11.2"; then
    section "Installing Neovim..."
    sudo apt-get remove -y neovim neovim-runtime 2>/dev/null || true
    sudo rm -rf "/opt/nvim-linux-${BINARY_ARCH}"
    curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${BINARY_ARCH}.tar.gz" | sudo tar -C /opt -xz
    sudo ln -sfn "/opt/nvim-linux-${BINARY_ARCH}/bin/nvim" /usr/local/bin/nvim
    hash -r
  fi

  # docker-buildx (skip if docker-buildx-plugin from Docker's repo is already installed)
  if ! dpkg -l docker-buildx-plugin &>/dev/null; then
    sudo apt-get install -y docker-buildx 2>/dev/null || true
  fi

  # tldr: Debian Trixie+ replaced tldr with tealdeer
  if apt-cache show tealdeer &>/dev/null; then
    sudo apt-get install -y tealdeer
  else
    sudo apt-get install -y tldr
  fi

  # starship (not in Debian/Ubuntu repos)
  if ! command -v starship &>/dev/null; then
    section "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # lazygit (not in Ubuntu repos)
  if ! command -v lazygit &>/dev/null; then
    section "Installing lazygit..."
    local LAZYGIT_VERSION
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${BINARY_ARCH}.tar.gz" | tar xz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin/
    rm -f /tmp/lazygit
  fi

  # lazydocker (not in Ubuntu repos)
  if ! command -v lazydocker &>/dev/null; then
    section "Installing lazydocker..."
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
  fi

  # tree-sitter-cli: prefer the distro package when available (Debian Trixie+/Ubuntu 24.04+),
  # otherwise fall back to the upstream binary release for older releases.
  if ! command -v tree-sitter &>/dev/null; then
    section "Installing tree-sitter-cli..."
    if sudo apt-get install -y tree-sitter-cli 2>/dev/null; then
      :
    else
      local TS_ARCH
      case "$DEB_ARCH" in
      amd64) TS_ARCH="x64" ;;
      arm64) TS_ARCH="arm64" ;;
      esac
      local TS_VERSION
      TS_VERSION=$(curl -fsSL "https://api.github.com/repos/tree-sitter/tree-sitter/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
      curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VERSION}/tree-sitter-linux-${TS_ARCH}.gz" | gunzip > /tmp/tree-sitter
      sudo install -m 0755 /tmp/tree-sitter /usr/local/bin/tree-sitter
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
    sudo systemctl enable --now ssh.service
    echo "✓ sshd"
  fi
}
