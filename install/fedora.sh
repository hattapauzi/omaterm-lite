install_packages() {
  section "Updating system packages..."
  sudo dnf upgrade -y

  section "Installing Fedora packages..."
  sudo dnf install -y @development-tools \
    git openssh-server sudo less net-tools whois \
    zsh fzf ripgrep zoxide tmux btop man-db tldr \
    vim neovim \
    clang llvm rust cargo libyaml \
    curl wget \
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
