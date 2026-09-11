# Sudoedit nvim editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After install, `sudoedit` opens the host's nvim binary as the invoking user so it loads `~/.config/nvim`.

**Architecture:** `configure_sudo_editor` in `install.sh` writes `/etc/sudoers.d/20-omaterm-editor` after packages exist. The drop-in sets `Defaults editor=` to the absolute nvim path (optional `/usr/bin/vi` suffix) and `env_keep` for `EDITOR VISUAL SUDO_EDITOR`. Lite and Hatta shell configs export those three variables as `nvim`. visudo rejects user-owned sudoers files, so the temp file is `chown root:root` and checked with `as_root visudo` before `install`.

**Tech Stack:** Bash installer (`set -euo pipefail`), sudoers.d, visudo, existing `as_root` helper. No new packages.

## Global Constraints

- `install.sh` is `set -euo pipefail`; `command -v nvim` and `visudo` must be written so failures take the specified branch, not an implicit `set -e` abort.
- Do not replace the existing `EXIT` trap that removes `INSTALLER_DIR`. Use `mktemp` plus `as_root rm -f` / `rm -f` on every path out of `configure_sudo_editor`.
- Drop-in path is `/etc/sudoers.d/20-omaterm-editor` only. Do not edit `10-omaterm-<admingroup>`.
- Ownership must be `root:root` mode `0440` via `as_root install -m 0440 -o root -g root`.
- Call site is `run_installation`, immediately after the package-install / `OMATERM_SKIP_PACKAGES` block, before `configure_shell`.
- Missing nvim after a full `install_packages`: exit 1. Missing nvim with `OMATERM_SKIP_PACKAGES=1`: warn, return 0, continue the rest of install.
- `/usr/bin/vi` is appended only when `[ -x /usr/bin/vi ]`.
- Do not change `config/lite/zshrc` early-return. Do not copy nvim config to `/root`. No Debian `update-alternatives`.
- Two-space indent, lowercase function and local names.

## File structure

| File | Responsibility |
|---|---|
| `config/shell/envs` | Lite interactive `EDITOR` / `VISUAL` / `SUDO_EDITOR` |
| `config/hatta/zshrc` | Hatta same three exports (already before the interactive early-return) |
| `install.sh` | `configure_sudo_editor` and the `run_installation` call |

Do not split `install.sh`. Do not add a test framework. Verification is `bash -n`, file assertions, and Docker images.

---

### Task 1: Shell editor exports

**Files:**
- Modify: `config/shell/envs`
- Modify: `config/hatta/zshrc` (environment block around `export EDITOR="nvim"`)
- Test: the grep commands in this task

**Interfaces:**
- Consumes: existing `export EDITOR="nvim"` in both files
- Produces: both files also export `VISUAL="nvim"` and `SUDO_EDITOR="nvim"`

- [ ] **Step 1: Write the failing checks**

Run:

```bash
grep -q 'export VISUAL="nvim"' config/shell/envs
grep -q 'export SUDO_EDITOR="nvim"' config/shell/envs
grep -q 'export VISUAL="nvim"' config/hatta/zshrc
grep -q 'export SUDO_EDITOR="nvim"' config/hatta/zshrc
```

Expected: at least one grep exits 1 (those lines do not exist yet).

- [ ] **Step 2: Update lite envs**

Replace `config/shell/envs` with:

```bash
export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
export PATH="$PATH:$HOME/.local/bin"
export INPUTRC="$HOME/.config/shell/inputrc"
```

- [ ] **Step 3: Update Hatta zshrc**

In `config/hatta/zshrc`, change the environment block to:

```zsh
# Environment
export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
export PATH="$PATH:$HOME/.local/bin"
```

Keep this block above `[[ $- != *i* ]] && return`. Do not move or add exports in `config/lite/zshrc` or `.zprofile`.

- [ ] **Step 4: Re-run the checks**

Run the four greps from Step 1, plus:

```bash
grep -n 'export EDITOR="nvim"' config/hatta/zshrc
```

Expected: all greps exit 0. Hatta `EDITOR` line number is still before the early-return (`[[ $- != *i* ]] && return` is around line 34).

- [ ] **Step 5: Commit**

```bash
git add config/shell/envs config/hatta/zshrc
git commit -m "$(cat <<'EOF'
feat: export VISUAL and SUDO_EDITOR as nvim

EOF
)"
```

---

### Task 2: Sudoers drop-in in the installer

**Files:**
- Modify: `install.sh` (add `configure_sudo_editor` near `configure_shell`; call it from `run_installation`)
- Test: `bash -n install.sh` and the grep/order checks in this task

**Interfaces:**
- Consumes: existing `as_root`, `section`; `OMATERM_SKIP_PACKAGES`; `command -v nvim` after packages
- Produces: `configure_sudo_editor` with no arguments; writes `/etc/sudoers.d/20-omaterm-editor` or skips/exits as specified

- [ ] **Step 1: Write the failing checks**

Run:

```bash
grep -q 'configure_sudo_editor' install.sh
grep -q '20-omaterm-editor' install.sh
```

Expected: both exit 1.

- [ ] **Step 2: Add `configure_sudo_editor` to `install.sh`**

Place it immediately above `configure_shell()`. Use this function body (do not add a second `trap`):

```bash
configure_sudo_editor() {
  local nvim_path tmp editor_value

  section "Configuring sudoedit editor..."

  nvim_path="$(command -v nvim || true)"
  if [ -z "$nvim_path" ]; then
    if [ "${OMATERM_SKIP_PACKAGES:-0}" = "1" ]; then
      echo "⚠ nvim not found; skipping sudoedit editor config"
      return 0
    fi
    echo "Error: nvim not found; required to configure sudoedit" >&2
    exit 1
  fi

  tmp="$(mktemp)"
  if [ -x /usr/bin/vi ]; then
    editor_value="${nvim_path}:/usr/bin/vi"
  else
    editor_value="$nvim_path"
  fi

  printf 'Defaults editor="%s"\nDefaults env_keep += "EDITOR VISUAL SUDO_EDITOR"\n' "$editor_value" >"$tmp"

  # visudo rejects user-owned sudoers files; chown before -cf.
  as_root chown root:root "$tmp"
  as_root chmod 0440 "$tmp"
  if ! as_root visudo -cf "$tmp"; then
    as_root rm -f "$tmp"
    echo "Error: sudoers editor drop-in failed visudo check" >&2
    exit 1
  fi

  as_root install -m 0440 -o root -g root "$tmp" /etc/sudoers.d/20-omaterm-editor
  as_root rm -f "$tmp"

  if ! as_root visudo -c; then
    as_root rm -f /etc/sudoers.d/20-omaterm-editor
    echo "Error: sudoers invalid after installing editor drop-in" >&2
    exit 1
  fi

  echo "✓ sudoedit editor: nvim"
}
```

- [ ] **Step 3: Call it from `run_installation`**

In `run_installation`, after the package / skip block and before `configure_shell`, it must look like this:

```bash
  # OS-specific package installation
  if [ "${OMATERM_SKIP_PACKAGES:-0}" = "1" ]; then
    section "Skipping package installation (OMATERM_SKIP_PACKAGES=1)"
  else
    install_packages
  fi

  configure_sudo_editor

  # Make Zsh the default shell before Hatta/lite writes shell config
  configure_shell
```

- [ ] **Step 4: Syntax-check and order-check**

Run:

```bash
bash -n install.sh install/*.sh bin/omaterm-*
python3 - <<'PY'
from pathlib import Path
text = Path("install.sh").read_text()
i_skip = text.index("Skipping package installation")
i_fn = text.index("configure_sudo_editor() {")
i_call = text.index("\n  configure_sudo_editor\n")
i_shell = text.index("configure_shell")
assert i_fn < i_call, "function must be defined before the call"
assert i_skip < i_call < i_shell, "call must sit after package/skip and before configure_shell"
print("order ok")
PY
```

Expected: `bash -n` silent, exit 0. Python prints `order ok`.

- [ ] **Step 5: Commit**

```bash
git add install.sh
git commit -m "$(cat <<'EOF'
feat: point sudoedit at nvim via sudoers

EOF
)"
```

---

### Task 3: Distro verification

**Files:**
- Test only: Dockerfiles are not modified. Use the existing `Dockerfile`, `Dockerfile.debian`, `Dockerfile.fedora`, `Dockerfile.hatta`.

**Interfaces:**
- Consumes: Task 1 exports and Task 2 drop-in
- Produces: evidence that each image's sudoers file and shell configs match the spec

- [ ] **Step 1: Arch image**

Run:

```bash
docker build -t omaterm-test-arch -f Dockerfile .
```

Expected: build succeeds (installer ran as `omaterm-lite`).

Then:

```bash
docker run --rm --entrypoint bash omaterm-test-arch -lc '
set -euo pipefail
visudo -c
stat -c "%U:%G %a" /etc/sudoers.d/20-omaterm-editor | grep -x "root:root 440"
first=$(sed -n "s/^Defaults editor=\"\\([^\":]*\\).*/\\1/p" /etc/sudoers.d/20-omaterm-editor)
test -x "$first"
test "$(basename "$first")" = nvim
grep -q "Defaults env_keep += \"EDITOR VISUAL SUDO_EDITOR\"" /etc/sudoers.d/20-omaterm-editor
grep -q "export VISUAL=\"nvim\"" "$HOME/.config/shell/envs"
grep -q "export SUDO_EDITOR=\"nvim\"" "$HOME/.config/shell/envs"
export EDITOR=nvim
test "$(sudo printenv EDITOR)" = nvim
echo ARCH_OK
'
```

Expected: prints `ARCH_OK`. First `editor=` path is executable nvim (usually `/usr/bin/nvim`).

- [ ] **Step 2: Debian image**

Run:

```bash
docker build -t omaterm-test-debian -f Dockerfile.debian .
docker run --rm --entrypoint bash omaterm-test-debian -lc '
set -euo pipefail
visudo -c
stat -c "%U:%G %a" /etc/sudoers.d/20-omaterm-editor | grep -x "root:root 440"
first=$(sed -n "s/^Defaults editor=\"\\([^\":]*\\).*/\\1/p" /etc/sudoers.d/20-omaterm-editor)
test -x "$first"
test "$(basename "$first")" = nvim
# Debian ships nvim under /usr/local/bin; do not require it to match this shell PATH.
export EDITOR=nvim
test "$(sudo printenv EDITOR)" = nvim
echo DEBIAN_OK
'
```

Expected: prints `DEBIAN_OK`. `$first` is typically `/usr/local/bin/nvim`.

- [ ] **Step 3: Fedora image**

Run:

```bash
docker build -t omaterm-test-fedora -f Dockerfile.fedora .
docker run --rm --entrypoint bash omaterm-test-fedora -lc '
set -euo pipefail
visudo -c
stat -c "%U:%G %a" /etc/sudoers.d/20-omaterm-editor | grep -x "root:root 440"
first=$(sed -n "s/^Defaults editor=\"\\([^\":]*\\).*/\\1/p" /etc/sudoers.d/20-omaterm-editor)
test -x "$first"
test "$(basename "$first")" = nvim
export EDITOR=nvim
test "$(sudo printenv EDITOR)" = nvim
echo FEDORA_OK
'
```

Expected: prints `FEDORA_OK`.

- [ ] **Step 4: Hatta image**

Requires `omaterm-test-arch` from Step 1 (`OMATERM_SKIP_PACKAGES=1` here; nvim already on PATH from the Arch image, so the drop-in must still be written).

```bash
docker build -t omaterm-test-hatta -f Dockerfile.hatta .
docker run --rm --entrypoint bash omaterm-test-hatta -lc '
set -euo pipefail
visudo -c
stat -c "%U:%G %a" /etc/sudoers.d/20-omaterm-editor | grep -x "root:root 440"
first=$(sed -n "s/^Defaults editor=\"\\([^\":]*\\).*/\\1/p" /etc/sudoers.d/20-omaterm-editor)
test -x "$first"
test "$(basename "$first")" = nvim
grep -q "export VISUAL=\"nvim\"" "$HOME/.zshrc"
grep -q "export SUDO_EDITOR=\"nvim\"" "$HOME/.zshrc"
# Hatta does not install config/shell/envs
test ! -f "$HOME/.config/shell/envs"
export EDITOR=nvim
test "$(sudo printenv EDITOR)" = nvim
echo HATTA_OK
'
```

Expected: prints `HATTA_OK`. Existing Hatta Dockerfile checks still pass during `docker build`.

- [ ] **Step 5: Commit if Dockerfiles were not changed**

No commit if only verification ran. If a drop-in or export bug was fixed in `install.sh` / configs, commit that fix with `fix:` and re-run the failing image step.
