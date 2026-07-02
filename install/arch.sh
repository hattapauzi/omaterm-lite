install_packages() {
  local official_pkgs=(
    base-devel git openssh sudo less inetutils whois
    zsh starship fzf ripgrep eza zoxide tmux btop man-db tldr
    vim neovim
    clang llvm rust libyaml
    lazygit lazydocker
    docker docker-buildx docker-compose
    kitty-terminfo
  )

  section "Installing Arch packages..."
  sudo pacman -Syu --needed --noconfirm "${official_pkgs[@]}"
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

  sudo systemctl enable docker.service
  sudo systemctl start --no-block docker.service
  echo "✓ Docker"

  if [ "${OMATERM_PROFILE:-server}" = "server" ]; then
    sudo systemctl enable --now sshd.service
    echo "✓ sshd"
  fi
}
