# Omaterm Lite

A lightweight Omakase terminal setup for Arch/Debian/Ubuntu/Fedora, tuned for server environments.

## Requirements

- Base Arch/Debian/Ubuntu/Fedora Linux installation
- Internet connection
- `sudo` privileges

## Install

```bash
curl -fsSL https://omaterm.hatta.cc/install | bash
```

## What it sets up

- **Shell**: Bash with starship prompt, fzf, eza, zoxide
- **Editors**: Neovim (LazyVim)
- **Dev tools**: docker, lazygit, lazydocker
- **Networking**: SSH
- **Git**: Interactive config for user name/email, helpful aliases

## Docker

```bash
docker run -it -v omaterm-lite-home:/home/omaterm-lite ghcr.io/hattapauzi/omaterm-lite
```

The named volume persists your home directory across container restarts, including git config, shell history, and projects.

## Interactive prompts

During installation you'll be asked for:

- Git user name
- Git email address

And you'll be offered to setup:

- SSH public keys
