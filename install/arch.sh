install_packages() {
  local official_pkgs=(
    base-devel git openssh sudo less inetutils whois
    zsh starship fzf eza zoxide tmux btop man-db tldr
    vim neovim
    clang llvm rust libyaml
    lazygit lazydocker
    docker docker-buildx docker-compose
    kitty-terminfo
  )

  section "Installing Arch packages..."
  sudo pacman -Syu --needed --noconfirm "${official_pkgs[@]}"
}

install_npm_tools() {
  :
}

enable_services() {
  section "Enabling services..."

  sudo systemctl enable docker.service
  sudo systemctl start --no-block docker.service
  echo "✓ Docker"

  sudo systemctl enable --now sshd.service
  echo "✓ sshd"
}
