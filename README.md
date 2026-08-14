# Omaterm Lite

A lightweight Omakase terminal setup for Arch/Debian/Ubuntu/Fedora. Desktop installs can choose the **Hatta** shell persona; servers stay on the minimal **lite** path.

## Flavors

| Flavor | When | Shell persona |
|---|---|---|
| **hatta** | Desktop only (prompted, or set explicitly) | Oh My Zsh + Powerlevel10k (vendored config, no p10k wizard) + Forge; Nerd Font check; no Starship |
| **lite** | Default on server; optional on desktop | Zsh + Starship + shared shell config |

Server profile always forces `lite` and enables SSH by default. Desktop auto-detects and asks whether to use Hatta.

```bash
# Hatta (desktop)
OMATERM_PROFILE=desktop OMATERM_FLAVOR=hatta bash install.sh

# lite (explicit)
OMATERM_FLAVOR=lite bash install.sh
```

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
| `OMATERM_PROFILE` | `desktop`, `server` | *Auto-detected* | Desktop enables interactive options and flavor selection. Server forces `lite` and enables SSH by default. |
| `OMATERM_FLAVOR` | `hatta`, `lite` | `lite` (Server) / *Prompted* (Desktop) | Shell persona. See [Flavors](#flavors). |
| `OMATERM_REF` | Any branch/commit | `master` | The git branch or tag of the repository to clone and install. |
| `OMATERM_ALLOW_ROOT` | `1`, `0` | `0` | If set to `1`, allows the installer to run and configure packages directly under the `root` user without prompting to switch to a non-root user. |
| `OMATERM_INSTALLER_DIR` | Path to local directory | *None* | Runs the installer using a local directory instead of cloning the repository from GitHub. |
| `OMATERM_SKIP_PACKAGES` | `1`, `0` | `0` | If set to `1`, skips distro package install/upgrade. Used by the Hatta test image, which already has packages from `omaterm-test-arch`. |

Example:
```bash
# Force desktop profile and Hatta flavor installation locally
OMATERM_PROFILE=desktop OMATERM_FLAVOR=hatta bash install.sh
```

## What it sets up

- **Shell**: Zsh with fzf, eza, zoxide, and tmux (not auto-started). Prompt and shell persona depend on [flavor](#flavors): Hatta (OMZ + Powerlevel10k + Forge) or lite (Starship).
- **Editors**: Neovim (LazyVim)
- **Dev tools**: docker, lazygit, lazydocker
- **Networking**: SSH
- **Git**: Interactive config for user name/email, helpful aliases

## About

Omaterm Lite is a fork of [basecamp/omaterm](https://github.com/basecamp/omaterm) (an Omakase terminal setup by DHH, related to [Omarchy](https://omarchy.org)).

- **This project** installs directly on Arch, Debian/Ubuntu, or Fedora hosts, with optional desktop/server profiles and Hatta/lite flavors.
- **Upstream today** is Docker-first: managed Omaterm boxes with a host `omaterm` CLI, agents, Tailscale, 1Password CLI, and related setup flows.

The projects have diverged; treat the lists below as what Lite deliberately omits relative to upstream's fuller tooling set, not as a live package sync.

### Package and setup differences

Removed packages/tools (relative to upstream-style installs):

- `tmux` auto-start (package still installed; shell launch does not enter tmux)
- `jq`
- `luarocks`
- `gum`
- `gh` / `github-cli`
- `fd`
- `1password-cli` / `op`
- `tailscale`
- `mise`
- Ruby via `mise`
- Node via `mise`
- `opencode` / `opencode-ai`
- `claude-code` / `@anthropic-ai/claude-code`
- `codex`
- `gemini`
- `hunk`
- `basecamp-cli`
- `pi`

Removed setup flows:

- tmux auto-start on shell launch
- GitHub CLI authentication prompt
- Tailscale setup prompt
- 1Password CLI setup
- npm/mise-based AI assistant installation
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
