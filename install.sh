#!/usr/bin/env bash
set -euo pipefail

# Common functions for Omaterm Lite installation
show_banner() {
  clear 2>/dev/null || true
  echo
  echo " ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████     ███        ▄████████    ▄████████   ▄▄▄▄███▄▄▄▄  
███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███ ▀█████████▄   ███    ███   ███    ███ ▄██▀▀▀███▀▀▀██▄
███    ███ ███   ███   ███   ███    ███    ▀███▀▀██   ███    █▀    ███    ███ ███   ███   ███
███    ███ ███   ███   ███   ███    ███     ███   ▀  ▄███▄▄▄      ▄███▄▄▄▄██▀ ███   ███   ███
███    ███ ███   ███   ███ ▀███████████     ███     ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ███   ███   ███
███    ███ ███   ███   ███   ███    ███     ███       ███    █▄  ▀███████████ ███   ███   ███
███    ███ ███   ███   ███   ███    ███     ███       ███    ███   ███    ███ ███   ███   ███
 ▀██████▀   ▀█   ███   █▀    ███    █▀     ▄████▀     ██████████   ███    ███  ▀█   ███   █▀ 
                                                                   ███    ███                "
}

section() {
  echo -e "\n==> $1"
}

detect_os() {
  if [ -f /etc/arch-release ]; then
    echo "arch"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/fedora-release ]; then
    echo "fedora"
  else
    return 1
  fi
}

as_root() {
  if [ "$EUID" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

prompt_confirm() {
  local prompt="$1"
  local default="${2:-y}"
  local suffix reply

  if [ "$default" = "y" ]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi

  while true; do
    printf "%s %s " "$prompt" "$suffix" >/dev/tty
    IFS= read -r reply </dev/tty || return 1
    reply="${reply,,}"

    case "$reply" in
    "") [ "$default" = "y" ] && return 0 || return 1 ;;
    y | yes) return 0 ;;
    n | no) return 1 ;;
    *) echo "Please answer yes or no." >/dev/tty ;;
    esac
  done
}

backup_file() {
  local target="$1"
  if [ -e "$target" ]; then
    cp -a "$target" "${target}.bak.$(date +%Y%m%d%H%M%S)"
    echo "✓ Backed up $(basename "$target")"
  fi
}

is_systemd() {
  [ "$(ps -p 1 -o comm= 2>/dev/null | tr -d ' ')" = "systemd" ]
}

default_install_user() {
  local users

  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    echo "$SUDO_USER"
    return
  fi

  mapfile -t users < <(awk -F: '$3 >= 1000 && $3 < 60000 && $1 != "nobody" { print $1 }' /etc/passwd)
  if [ "${#users[@]}" -eq 1 ]; then
    echo "${users[0]}"
  else
    echo "omaterm-lite"
  fi
}

prompt_username() {
  local default_user="$1"
  local username

  while true; do
    printf "User to use/create [%s]: " "$default_user" >/dev/tty
    IFS= read -r username </dev/tty || return 1
    username="${username:-$default_user}"

    if [ "$username" = "root" ]; then
      echo "Please choose a non-root user." >/dev/tty
    elif [[ "$username" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
      echo "$username"
      return 0
    else
      echo "Use a Linux username like 'omaterm' or 'alice'." >/dev/tty
    fi
  done
}

ensure_root_bootstrap_tools() {
  local os_id="$1"

  if command -v sudo &>/dev/null; then
    return
  fi

  section "Installing sudo..."
  case "$os_id" in
  arch)
    pacman -Syu --needed --noconfirm sudo
    ;;
  debian)
    apt-get update
    apt-get install -y sudo
    ;;
  fedora)
    dnf install -y sudo
    ;;
  esac
}

admin_group_for_os() {
  case "$1" in
  debian) echo "sudo" ;;
  arch | fedora) echo "wheel" ;;
  esac
}

ensure_install_user() {
  local username="$1"
  local os_id="$2"
  local admin_group

  if getent passwd "$username" &>/dev/null; then
    echo "✓ Using existing user: $username"
  else
    section "Creating user $username..."
    useradd -m -s /bin/bash "$username"
    echo "Set a password for $username. You'll use it for sudo during install."
    passwd "$username" </dev/tty
  fi

  admin_group="$(admin_group_for_os "$os_id")"
  getent group "$admin_group" &>/dev/null || groupadd "$admin_group"
  usermod -aG "$admin_group" "$username"

  mkdir -p /etc/sudoers.d
  printf "%%%s ALL=(ALL:ALL) ALL\n" "$admin_group" >"/etc/sudoers.d/10-omaterm-$admin_group"
  chmod 0440 "/etc/sudoers.d/10-omaterm-$admin_group"
  echo "✓ Added $username to $admin_group"
}

maybe_reexec_as_non_root() {
  local os_id="$1"
  local installer_dir="$2"
  local default_user target_user status

  if [ "$EUID" -ne 0 ] || [ "${OMATERM_ALLOW_ROOT:-}" = "1" ]; then
    return
  fi

  if [ ! -r /dev/tty ] || [ ! -w /dev/tty ]; then
    echo "Running as root without an interactive TTY; continuing as root."
    ensure_root_bootstrap_tools "$os_id"
    return
  fi

  echo
  echo "Omaterm Lite is running as root. If we continue, user config will be installed under /root."
  echo "It's usually better to install Omaterm Lite as a normal sudo-capable user."

  if ! prompt_confirm "Create/use a non-root user and run the install there instead?" "y"; then
    echo "Continuing as root. Set OMATERM_ALLOW_ROOT=1 to skip this prompt."
    ensure_root_bootstrap_tools "$os_id"
    return
  fi

  default_user="$(default_install_user)"
  target_user="$(prompt_username "$default_user")"

  ensure_root_bootstrap_tools "$os_id"
  ensure_install_user "$target_user" "$os_id"

  section "Restarting installer as $target_user..."
  chmod -R a+rX "$installer_dir"

  if sudo -iu "$target_user" env OMATERM_REF="$OMATERM_REF" OMATERM_PROFILE="${OMATERM_PROFILE:-}" bash "$installer_dir/install.sh"; then
    echo
    echo "Omaterm Lite installed for $target_user. You're back at the root shell."
    echo "To start using Omaterm Lite, either log out and log back in as $target_user, or run:"
    echo "  su - $target_user"
    exit 0
  else
    status=$?
    echo
    echo "Omaterm Lite install failed for $target_user. You're back at the root shell."
    exit "$status"
  fi
}

install_oh_my_zsh() {
  section "Installing Oh My Zsh..."
  if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✓ Oh My Zsh already installed"
    return
  fi
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

install_omz_plugins() {
  section "Installing OMZ plugins..."

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  clone_unless() {
    local url="$1" dest="$2"
    [ -d "$dest" ] || git clone --depth=1 "$url" "$dest"
  }

  clone_unless https://github.com/romkatv/powerlevel10k.git \
    "$zsh_custom/themes/powerlevel10k"
  clone_unless https://github.com/zsh-users/zsh-autosuggestions \
    "$zsh_custom/plugins/zsh-autosuggestions"
  clone_unless https://github.com/zsh-users/zsh-syntax-highlighting \
    "$zsh_custom/plugins/zsh-syntax-highlighting"

  echo "✓ Powerlevel10k theme + zsh-autosuggestions + zsh-syntax-highlighting"
}

install_forge() {
  if command -v forge &>/dev/null; then
    echo "✓ Forge already installed"
    return
  fi
  section "Installing Forge..."
  curl -fsSL https://forgecode.dev/cli | sh
}

check_nerdfont() {
  if command -v fc-list &>/dev/null && ! fc-list 2>/dev/null | grep -qi nerd; then
    echo
    echo "⚠ No NerdFont detected on the system."
    echo "  Powerlevel10k needs one for icons and prompt segments."
    echo "  Install one (e.g. ttf-hack-nerdfont on Arch, or download from nerdfonts.com)"
    echo "  then set it as your terminal's font."
  fi
}

install_hatta_shell() {
  install_oh_my_zsh
  export ZSH="$HOME/.oh-my-zsh"
  install_omz_plugins
  install_forge

  section "Dropping Hatta configs..."
  backup_file "$HOME/.zshrc"
  backup_file "$HOME/.p10k.zsh"
  backup_file "$HOME/.zprofile"

  cp -f "$INSTALLER_DIR/config/hatta/zshrc" "$HOME/.zshrc"
  cp -f "$INSTALLER_DIR/config/hatta/p10k.zsh" "$HOME/.p10k.zsh"
  cat >"$HOME/.zprofile" <<'EOF'
# .zprofile is intentionally empty.
# Previously sourced ~/.zshrc here, which caused .zshrc to run twice in login
# shells (e.g. inside tmux). That double-load let fzf rebind Tab after forge
# had already bound it, breaking the ":" sentinel completion in tmux.
# ~/.zshrc is sourced automatically by zsh for interactive shells.
EOF

  # Clean up _FORGE_*_LOADED markers that may have leaked into the systemd
  # user environment from a previous session. If left behind, these markers
  # cause the forge plugin guard in .zshrc to skip loading, breaking the
  # ":" command dispatch (e.g. ":conversation" shows zsh history modifiers
  # instead of running the forge command).
  if command -v systemctl &>/dev/null && systemctl --user show-environment &>/dev/null; then
    systemctl --user unset-environment _FORGE_PLUGIN_LOADED _FORGE_THEME_LOADED 2>/dev/null || true
  fi

  echo "✓ Hatta .zshrc + .p10k.zsh + .zprofile"

  check_nerdfont
}

install_configs() {
  section "Installing configs..."
  mkdir -p "$HOME/.config"
  backup_file "$HOME/.config/nvim"
  backup_file "$HOME/.config/lazygit"
  cp -Rf "$INSTALLER_DIR/config/nvim" "$HOME/.config/"
  cp -Rf "$INSTALLER_DIR/config/lazygit" "$HOME/.config/"
  echo "✓ Neovim"
  echo "✓ Lazygit"

  case "$OMATERM_FLAVOR" in
  lite)
    backup_file "$HOME/.config/starship.toml"
    cp -f "$INSTALLER_DIR/config/starship.toml" "$HOME/.config/"
    echo "✓ Starship"

    if [ -d "$HOME/.config/shell" ] && [ -n "$(ls -A "$HOME/.config/shell" 2>/dev/null)" ]; then
      backup_file "$HOME/.config/shell"
    fi
    mkdir -p "$HOME/.config/shell"
    cp -Rf "$INSTALLER_DIR/config/shell/"* "$HOME/.config/shell/"
    echo "✓ Shell config"

    backup_file "$HOME/.zshrc"
    cp -f "$INSTALLER_DIR/config/lite/zshrc" "$HOME/.zshrc"
    backup_file "$HOME/.zprofile"
    cp -f "$INSTALLER_DIR/config/lite/zprofile" "$HOME/.zprofile"
    echo "✓ Zsh config"
    ;;
  hatta)
    # Hatta drops starship; p10k (via OMZ) owns the prompt.
    backup_file "$HOME/.config/starship.toml"
    rm -f "$HOME/.config/starship.toml"
    # Hatta's shell persona (OMZ + p10k + forge) is installed separately.
    ;;
  esac
}

install_bins() {
  section "Installing bins..."
  mkdir -p "$HOME/.local/bin"
  cp -Rf "$INSTALLER_DIR/bin/"* "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/"*
  echo "✓ omaterm-ssh"
  echo "✓ omaterm-theme"
  echo "✓ omaterm-refresh"
}

configure_shell() {
  section "Configuring shell..."
  local username zsh_path current_shell

  username="${USER:-$(id -un)}"
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "$username" | cut -d: -f7)"

  if [ "$current_shell" != "$zsh_path" ]; then
    as_root usermod -s "$zsh_path" "$username"
  fi

  export SHELL="$zsh_path"
  echo "✓ Zsh"
}

setup_docker_group() {
  local current_user="${USER:-$(id -un)}"
  if ! groups "$current_user" | grep -q docker; then
    if command -v usermod &>/dev/null; then
      sudo usermod -aG docker "$current_user"
    else
      sudo adduser "$current_user" docker
    fi
  fi
}

is_desktop() {
  # Xorg / X classic display servers
  command -v Xorg >/dev/null 2>&1 && return 0
  command -v X >/dev/null 2>&1 && return 0
  command -v startx >/dev/null 2>&1 && return 0

  # Generic *-session entry points (GNOME, Cinnamon, MATE, LXQt, XFCE ...)
  local s
  for s in /usr/bin/*-session; do
    [ -e "$s" ] && return 0
  done

  # Wayland compositors + KDE Plasma entry points (don't follow the *-session pattern)
  local c
  for c in sway weston hyprland wayfire river labwc kwin_wayland mutter gnome-shell startplasma plasmashell; do
    command -v "$c" >/dev/null 2>&1 && return 0
  done

  return 1
}

# OMATERM_PROFILE=desktop|server overrides auto-detection (used by CI/Docker).
resolve_profile() {
  section "Detecting profile..."
  case "${OMATERM_PROFILE:-}" in
    desktop | server) ;;
    "")
      if is_desktop; then
        OMATERM_PROFILE=desktop
      else
        OMATERM_PROFILE=server
      fi
      ;;
    *)
      echo "Error: invalid OMATERM_PROFILE='${OMATERM_PROFILE:-}' (use 'desktop' or 'server')" >&2
      exit 1
      ;;
  esac

  mkdir -p "$HOME/.config/omaterm"
  echo "$OMATERM_PROFILE" >"$HOME/.config/omaterm/profile"
  echo "✓ Profile: $OMATERM_PROFILE (shell stays login-mode adaptive; sshd follows profile)"
}

# OMATERM_FLAVOR=hatta|lite selects shell persona (desktop only; server forces lite).
resolve_flavor() {
  mkdir -p "$HOME/.config/omaterm"

  # Server profile never offers Hatta mode — keeps current behavior unchanged.
  if [ "$OMATERM_PROFILE" = "server" ]; then
    OMATERM_FLAVOR="lite"
    echo "$OMATERM_FLAVOR" >"$HOME/.config/omaterm/flavor"
    return
  fi

  section "Selecting flavor..."
  case "${OMATERM_FLAVOR:-}" in
    hatta | lite) ;;
    "")
      local persisted=""
      [ -f "$HOME/.config/omaterm/flavor" ] && persisted="$(cat "$HOME/.config/omaterm/flavor")"
      case "$persisted" in
        hatta | lite) OMATERM_FLAVOR="$persisted" ;;
        *)
          echo "Omaterm Lite's Hatta flavor adds Oh My Zsh + Powerlevel10k + Forge."
          if prompt_confirm "Use the Hatta terminal setup?" "n"; then
            OMATERM_FLAVOR="hatta"
          else
            OMATERM_FLAVOR="lite"
          fi
          ;;
      esac
      ;;
    *)
      echo "Error: invalid OMATERM_FLAVOR='${OMATERM_FLAVOR:-}' (use 'hatta' or 'lite')" >&2
      exit 1
      ;;
  esac

  echo "$OMATERM_FLAVOR" >"$HOME/.config/omaterm/flavor"
  echo "✓ Flavor: $OMATERM_FLAVOR"
}

interactive_setup() {
  section "Interactive setup..."

  if grep -qi proxmox /sys/class/dmi/id/product_name 2>/dev/null && [ -e /dev/ttyS0 ]; then
    if ! systemctl is-enabled serial-getty@ttyS0.service &>/dev/null; then
      echo
      if prompt_confirm "Proxmox VM detected with serial port. Enable serial console?" "y"; then
        sudo systemctl enable serial-getty@ttyS0.service
        sudo systemctl start serial-getty@ttyS0.service
        echo "✓ Serial console enabled on ttyS0"
      fi
    fi
  fi
}

finish() {
  section "Finished!"
  echo "Now logout and back in for everything to take effect"
}

configure_parallel_builds() {
  section "Configuring parallel compilation..."
  export MAKEFLAGS="-j$(nproc)"

  if [ -f /etc/makepkg.conf ]; then
    sudo sed -i "s/^#\?MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf
  fi

  echo "✓ Using $(nproc) cores for compilation"
}

run_installation() {
  resolve_profile
  resolve_flavor

  # Use all cores for compilation
  configure_parallel_builds

  # OS-specific package installation
  install_packages

  # Make Zsh the default shell before Hatta/lite writes shell config
  configure_shell

  # Hatta flavor: install OMZ + p10k + forge + drop config
  if [ "$OMATERM_FLAVOR" = "hatta" ]; then
    install_hatta_shell
  fi

  # Configs and bins
  install_configs
  install_bins

  # OS-specific service enabling
  enable_services

  # Setup Docker group
  setup_docker_group

  # Interactive setup
  interactive_setup

  # Done!
  finish
}

# Getting started
show_banner
section "Installing Omaterm Lite..."

if ! OS_ID="$(detect_os)"; then
  echo "Error: Unsupported operating system"
  echo "Omaterm Lite supports Arch Linux, Debian/Ubuntu, and Fedora"
  exit 1
fi

# Ensure correct git is installed
if ! command -v git &>/dev/null; then
  case "$OS_ID" in
  arch) as_root pacman -Syu --needed --noconfirm git ;;
  debian) as_root apt-get update && as_root apt-get install -y git ;;
  fedora) as_root dnf install -y git ;;
  esac
fi

REPO="https://github.com/hattapauzi/omaterm-lite.git"
OMATERM_REF="${OMATERM_REF:-master}"

if [ -n "${OMATERM_INSTALLER_DIR:-}" ] && [ -d "$OMATERM_INSTALLER_DIR" ]; then
  INSTALLER_DIR="$OMATERM_INSTALLER_DIR"
  echo "Using local installer dir: $INSTALLER_DIR"
else
  INSTALLER_DIR="$(mktemp -d)"
  trap 'rm -rf "$INSTALLER_DIR"' EXIT
  echo "Cloning Omaterm Lite from $REPO ($OMATERM_REF)..."
  git clone --depth 1 --branch "$OMATERM_REF" "$REPO" "$INSTALLER_DIR"
fi
maybe_reexec_as_non_root "$OS_ID" "$INSTALLER_DIR"

# OS detection and dispatch
case "$OS_ID" in
arch) source "$INSTALLER_DIR/install/arch.sh" ;;
debian) source "$INSTALLER_DIR/install/debian.sh" ;;
fedora) source "$INSTALLER_DIR/install/fedora.sh" ;;
esac

run_installation
