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

## Configuration & Customization

The installer supports customization via environment variables:

| Variable | Values | Default | Description |
|---|---|---|---|
| `OMATERM_PROFILE` | `desktop`, `server` | *Auto-detected* | Customizes system configurations. Desktop profile enables graphical/interactive elements and allows selecting a flavor. Server profile forces `lite` flavor and enables SSH service by default. |
| `OMATERM_FLAVOR` | `hatta`, `lite` | `lite` (Server) / *Prompted* (Desktop) | Selects the shell/terminal persona. The `hatta` flavor installs Oh My Zsh, Powerlevel10k, and Forge. The `lite` flavor sets up a lighter Zsh config with the Starship prompt. |
| `OMATERM_REF` | Any branch/commit | `master` | The git branch or tag of the repository to clone and install. |
| `OMATERM_ALLOW_ROOT` | `1`, `0` | `0` | If set to `1`, allows the installer to run and configure packages directly under the `root` user without prompting to switch to a non-root user. |
| `OMATERM_INSTALLER_DIR` | Path to local directory | *None* | Runs the installer using a local directory instead of cloning the repository from GitHub. |

Example:
```bash
# Force desktop profile and hatta flavor installation locally
OMATERM_PROFILE=desktop OMATERM_FLAVOR=hatta bash install.sh
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

# Hatta flavor (requires building omaterm-test-arch first)
docker build -t omaterm-test-hatta -f Dockerfile.hatta .
docker run -it --rm omaterm-test-hatta
```

Use `--rm` to remove the container when you exit. The image remains available and can be reused until you rebuild or remove it.

To persist the test user's home directory between runs, mount a named volume:

```bash
docker run -it --rm \
  -v omaterm-test-debian-home:/home/omaterm-lite \
  omaterm-test-debian
```

Use the same volume pattern for other images (Arch, Fedora, or Hatta) by changing the image and volume names.

The first container startup runs `omaterm-setup`, which may prompt for Git identity setup. Subsequent starts with a persisted home directory skip the setup after `~/.omaterm-setup-done` exists.

Clean up local test images when needed:

```bash
docker rmi omaterm-test-arch omaterm-test-debian omaterm-test-fedora omaterm-test-hatta
```

