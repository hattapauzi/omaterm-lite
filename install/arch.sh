install_packages() {
  local official_pkgs=(
    base-devel git openssh sudo less inetutils whois
    zsh starship fzf ripgrep eza zoxide tmux btop man-db
    vim neovim
    clang llvm rust libyaml
    lazygit lazydocker
    docker docker-buildx docker-compose
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
