# Default sudoedit editor: nvim

## Goal

After install, `sudoedit` (and `sudo -e`) opens Neovim as the invoking user, so it loads the Omaterm config at `~/.config/nvim`. `visudo` uses the same editor list.

This applies to lite and Hatta, on Arch, Debian/Ubuntu, and Fedora.

## Non-goals

- Debian `update-alternatives` for `/usr/bin/editor`
- Copying Neovim config to `/root`
- Per-user `Defaults:username` sudoers
- Changing `sudo nvim`, which still runs as root and uses root's config
- Setting a system-wide editor for cron, `git`, or GUI apps beyond the shell exports below
- Moving lite's editor exports before the interactive early-return in `config/lite/zshrc`

## Current behavior

Lite already exports `EDITOR=nvim` from `config/shell/envs`. That file is interactive-only: `config/lite/zshrc` returns on `[[ $- != *i* ]]`, then sources `~/.config/shell/all`, which sources `envs`. Hatta already exports `EDITOR=nvim` from `config/hatta/zshrc` before that same early-return, so Hatta non-interactive zsh still has `EDITOR`.

`sudo` uses `env_reset` by default, so those variables are dropped. `sudoedit` then falls back to the distro `editor` list (vi or nano). Neither flavor sets `VISUAL` or `SUDO_EDITOR`. The installer does not write an editor drop-in under `/etc/sudoers.d`. Privilege sudoers live in `10-omaterm-<admingroup>` (`install.sh` `ensure_install_user`).

`install.sh` uses `set -euo pipefail`. `command -v` and `visudo` both exit non-zero on failure, so a literal `nvim_path=$(command -v nvim)` never reaches an empty-check.

## Target behavior

1. Shell: `EDITOR`, `VISUAL`, and `SUDO_EDITOR` are all `nvim` (the command name, not an absolute path).
2. Sudo: a drop-in owned by `root:root` mode `0440` keeps those three variables and sets `editor` to the absolute `nvim` path found at install time. If `/usr/bin/vi` exists and is executable, append it as a best-effort fallback. Minimal images may not ship vi; that fallback is not required for the feature to succeed.
3. `sudoedit` runs that nvim as the user. LazyVim stays in `~/.config/nvim`. Root's home is untouched.

`sudoedit` uses `SUDO_EDITOR`, then `VISUAL`, then `EDITOR`, when the named editor exists and is allowed. If those are unset (lite non-interactive zsh never loads `envs`) or the bare name `nvim` is not in the list, sudo uses the first `editor=` entry. That entry is the absolute nvim path captured at install, including Debian's `/usr/local/bin/nvim`. Either way `sudoedit` opens this Neovim.

Lite stays interactive-only for the three exports. Hatta keeps them before the early-return. That asymmetry is existing and intentional: lite's early-return avoids loading aliases, functions, and tool init for scripts. This change does not move lite exports earlier. `sudoedit` does not depend on them because of the sudoers `editor=` list.

## Installer

Add `configure_sudo_editor` in `install.sh`. Call it from `run_installation` immediately after the package-install / `OMATERM_SKIP_PACKAGES` block, before `configure_shell`. Do not call it from `ensure_install_user`; nvim is not guaranteed to exist that early.

This is a behavior change for skip-package runs: a config-only re-run with `OMATERM_SKIP_PACKAGES=1` and no `nvim` on `PATH` used to finish. It still finishes, but it now warns and skips the editor drop-in instead of aborting `run_installation` (configs, bins, and services still run). A full package install with no `nvim` after `install_packages` is a broken install and still exits 1.

### `configure_sudo_editor`

`install.sh` already has an `EXIT` trap that removes `INSTALLER_DIR`. Do not replace that trap. Use `mktemp` and `rm -f` on every path out of this function.

1. Resolve nvim without tripping `set -e`:

   ```bash
   nvim_path="$(command -v nvim || true)"
   ```

   If empty and `OMATERM_SKIP_PACKAGES=1`, print a warning that sudoedit will not be configured, return 0, write nothing. If empty and packages were installed this run, print that Neovim is required for sudoedit and exit 1.

2. `tmp="$(mktemp)"`. Write that file (not under `/etc`) with `printf`, not `echo`:

   ```
   Defaults editor="<nvim_path>"
   Defaults env_keep += "EDITOR VISUAL SUDO_EDITOR"
   ```

   If `[ -x /usr/bin/vi ]`, the editor value is `"<nvim_path>:/usr/bin/vi"` instead. Quote the `editor` value.

3. `chmod 0440 "$tmp"`. Check with `if ! visudo -cf "$tmp"; then rm -f "$tmp"; echo ... >&2; exit 1; fi`. Do not copy a file visudo rejected. A bare `visudo -cf` under `set -e` would skip this cleanup.

4. Install with root ownership, not a user-owned redirect:

   ```bash
   as_root install -m 0440 -o root -g root "$tmp" /etc/sudoers.d/20-omaterm-editor
   rm -f "$tmp"
   ```

   Overwrite on reinstall. `as_root cp` plus `chmod` is not enough unless `chown root:root` is explicit; `install -o root -g root` is the required form.

5. Live check: `if ! visudo -c; then as_root rm -f /etc/sudoers.d/20-omaterm-editor; echo ... >&2; exit 1; fi`.

Use a new file `20-omaterm-editor`. Do not reuse `10-omaterm-<admingroup>`.

`<nvim_path>` is whatever `command -v nvim` returns on that host. Debian/Ubuntu often uses `/usr/local/bin/nvim`. Arch and Fedora typically use `/usr/bin/nvim`. Do not hard-code one path.

## Shell config

In `config/shell/envs` (lite interactive path) and `config/hatta/zshrc` (Hatta environment block), set:

```
export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
```

Do not put these in `.zprofile`. Hatta's zprofile stays empty. Lite already sources `envs` from interactive zsh; login terminals that `exec bash -l` inherit exported variables from that zshrc. When they do not, the sudoers `editor` list still opens nvim.

## Error handling

| Case | Action |
|---|---|
| `nvim` missing, packages installed this run | Exit 1, no sudoers write, no temp file |
| `nvim` missing, `OMATERM_SKIP_PACKAGES=1` | Warn, skip drop-in, continue `run_installation` |
| `visudo -cf` on the temp file fails | `rm -f` temp, exit 1, leave existing sudoers alone |
| Live `visudo -c` fails after install | Remove `/etc/sudoers.d/20-omaterm-editor`, exit 1 |
| Function returns success | `rm -f` the temp file (already copied) |
| Reinstall | Overwrite the same drop-in after a successful check |

## Testing

- `bash -n install.sh install/*.sh bin/omaterm-*`
- Docker images: Arch, Debian, Fedora, and Hatta (Hatta because `config/hatta/zshrc` changes)
- In a built image:
  - `visudo -c` succeeds
  - `/etc/sudoers.d/20-omaterm-editor` exists; `stat -c '%U:%G %a'` is `root:root 440`
  - first `editor=` entry is executable and `basename` is `nvim` (do not compare it to the test shell's `command -v nvim`; Debian's binary may be `/usr/local/bin/nvim` and may be absent from a stripped test `PATH`)
  - lite: `~/.config/shell/envs` exports `EDITOR`, `VISUAL`, `SUDO_EDITOR`
  - Hatta: `~/.zshrc` exports the same three
  - From a shell with `EDITOR=nvim` exported, `sudo printenv EDITOR` prints `nvim`

Do not require an interactive `sudoedit` session in the image build.

## Files

| File | Change |
|---|---|
| `install.sh` | `configure_sudo_editor`; call from `run_installation` after the package/skip block, before `configure_shell` |
| `config/shell/envs` | `VISUAL`, `SUDO_EDITOR` |
| `config/hatta/zshrc` | `VISUAL`, `SUDO_EDITOR` |
| `config/lite/zshrc` | Unchanged (early-return stays; no editor exports added here) |
| `README.md` | Not required for this change |
