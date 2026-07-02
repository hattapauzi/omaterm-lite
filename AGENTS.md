# Repository Guidelines

## Project Structure & Module Organization

Omaterm Lite is a Bash-based terminal setup for Arch, Debian/Ubuntu, and Fedora. The main installer entrypoint is `install.sh`, with OS-specific package and service logic in `install/arch.sh`, `install/debian.sh`, and `install/fedora.sh`. User-facing helper commands live in `bin/` and are copied into `~/.local/bin` during installation. Default application configuration lives under `config/`, including Neovim, Starship, and Lazygit settings. The root `Dockerfile`, `Dockerfile.debian`, and `Dockerfile.fedora` provide distro-specific validation environments.

## Build, Test, and Development Commands

- `bash -n install.sh install/*.sh bin/omaterm-*`: syntax-check installer and helper scripts.
- `docker build -t omaterm-test-arch -f Dockerfile .`: build the Arch test image.
- `docker build -t omaterm-test-debian -f Dockerfile.debian .`: build the Debian test image.
- `docker build -t omaterm-test-fedora -f Dockerfile.fedora .`: build the Fedora test image.
- `docker run -it --rm omaterm-test-debian`: run a built image and exercise first-run setup.

Prefer Docker for installer validation. Do not run `install.sh` on your host unless you explicitly intend to change local shell, Docker, SSH, and user configuration.

## Coding Style & Naming Conventions

Write Bash scripts with `set -euo pipefail` and keep functions small. Follow the existing style: two-space indentation, lowercase function and local variable names, uppercase names for environment-style globals such as `OMATERM_REF`. Keep helper scripts named with the `omaterm-*` prefix. For Lua config, match the surrounding LazyVim plugin layout in `config/nvim/lua/`.

## Testing Guidelines

There is no formal automated test suite or coverage requirement. At minimum, run the Bash syntax check before submitting changes. For installer, package, service, or distro-specific edits, build and run the affected Docker image. When changing interactive flows, verify prompts in a fresh container and, when relevant, with a persisted home volume.

## Commit & Pull Request Guidelines

Recent history uses short imperative subjects, often with prefixes such as `feat:`, `fix:`, `style:`, and `merge:`. Keep commits focused and describe the user-visible effect. Pull requests should include a concise summary, affected distro(s), validation commands run, linked issues if any, and screenshots or terminal output when changing visible setup prompts or shell behavior.

## Security & Configuration Tips

Never commit private SSH keys, tokens, or machine-specific dotfiles. Treat `curl | bash`, SSH password-auth changes, sudoers edits, and Docker group changes as sensitive paths; review and test them in containers before changing defaults.
