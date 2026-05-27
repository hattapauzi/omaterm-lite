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

- **Shell**: Zsh with starship prompt, fzf, eza, zoxide (tmux available but not auto-started)
- **Editors**: Neovim (LazyVim)
- **Dev tools**: docker, lazygit, lazydocker
- **Networking**: SSH
- **Git**: Interactive config for user name/email, helpful aliases

## Lite changes

This fork removes packages and setup flows from the upstream Omaterm install that are not needed for a lighter Ubuntu/server-focused environment.

Removed packages/tools:

- `tmux` (package still installed; auto-start on shell launch is removed)
- `jq`
- `gum`
- `gh` / `github-cli`
- `tailscale`
- `mise`
- Ruby via `mise`
- Node via `mise`
- `opencode` / `opencode-ai`
- `claude-code` / `@anthropic-ai/claude-code`

Removed setup flows:
- tmux auto-start on shell launch (enters tmux automatically)
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

## Developer Docker testing

Build local images from the current working tree to test uncommitted changes across supported distros:

```bash
# Arch Linux
docker build -t omaterm-test-arch -f Dockerfile .
docker run -it --rm omaterm-test-arch

# Debian
docker build -t omaterm-test-debian -f Dockerfile.debian .
docker run -it --rm omaterm-test-debian

# Fedora
docker build -t omaterm-test-fedora -f Dockerfile.fedora .
docker run -it --rm omaterm-test-fedora
```

Use `--rm` to remove the container when you exit. The image remains available and can be reused until you rebuild or remove it.

To persist the test user's home directory between runs, mount a named volume:

```bash
docker run -it --rm \
  -v omaterm-test-debian-home:/home/omaterm-lite \
  omaterm-test-debian
```

Use the same volume pattern for Arch or Fedora by changing the image and volume names.

The first container startup runs `omaterm-setup`, which may prompt for Git identity setup. Subsequent starts with a persisted home directory skip the setup after `~/.omaterm-setup-done` exists.

Clean up local test images when needed:

```bash
docker rmi omaterm-test-arch omaterm-test-debian omaterm-test-fedora
```

