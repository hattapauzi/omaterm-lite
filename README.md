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

## Lite changes

This fork removes packages and setup flows from the upstream Omaterm install that are not needed for a lighter Ubuntu/server-focused environment.

Removed packages/tools:

- `jq`
- `luarocks`
- `gum`
- `gh` / `github-cli`
- `tailscale`
- `mise`
- Ruby via `mise`
- Node via `mise`
- `opencode` / `opencode-ai`
- `claude-code` / `@anthropic-ai/claude-code`

Removed setup flows:

- GitHub CLI authentication prompt
- Tailscale setup prompt
- npm-based AI assistant installation
- `mise` runtime installation for Node and Ruby

Kept intentionally:

- `clang`
- `llvm`
- Rust/Cargo equivalents

These are kept for Neovim/LazyVim native tooling, Tree-sitter, Mason-installed tools, and Fedora `eza` fallback support.

## Docker

```bash
docker run -it -v omaterm-lite-home:/home/omaterm-lite ghcr.io/hattapauzi/omaterm-lite
```

The named volume persists your home directory across container restarts, including git config, shell history, and projects.
