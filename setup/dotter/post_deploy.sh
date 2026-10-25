#!/usr/bin/env bash
# Setup that depends on the deployed files. Dotter renders this file with
# Handlebars and runs it from the repo root.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# A fresh machine has no fish environment yet. Tools such as brew fall back
# to ~/Library/Application Support on macOS without it.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# sysexits.h EX_TEMPFAIL. decrypt exits with it when it skips, so the
# next deploy retries.
readonly EX_TEMPFAIL=75

# The selected dotter packages. The quotes keep the Handlebars valid bash.
agents="{{#if dotter.packages.agents}}true{{/if}}"
desktop="{{#if dotter.packages.desktop}}true{{/if}}"

chmod 700 ~/.ssh

# mise caches exec() output, such as the GitHub tokens in mise.local.toml,
# as world-readable files. Other local accounts share the staff group.
mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/mise"
mkdir -p "$mise_cache"
chmod 700 "$mise_cache"

if [[ "$agents" == true ]]; then
  # Claude Code reads the shared skills through ~/.claude/skills. Dotter
  # links files, not directories, so the directory link lives here.
  if [[ -L ~/.claude/skills || ! -e ~/.claude/skills ]]; then
    ln -sfn ~/.agents/skills ~/.claude/skills
  else
    echo "warning: ~/.claude/skills is a directory; move it and deploy again" >&2
  fi

  # pi rewrites settings.json at runtime and has no settings layer, so the
  # keys the repo owns merge in from the linked settings.dotfiles.json.
  setup/merge-settings pi ~/.pi/agent/settings.dotfiles.json ~/.pi/agent/settings.json
fi

status=0
setup/onchange private private/home.tar.age -- setup/private/decrypt || status=$?
if ((status != 0 && status != EX_TEMPFAIL)); then
  exit "$status"
fi

# The archive can restore hooks for setup that would expose private
# details in this repo, such as logins with credentials from 1Password.
# Decrypt restores files as 0600, so bash runs each hook.
for hook in ~/.config/dotfiles/post-deploy.d/*; do
  if [[ -f "$hook" ]]; then
    bash "$hook"
  fi
done

# The repo runs jj colocated with git, but a fresh clone is plain git. jj
# takes it over once the package install has put jj in place, and tracks
# main as `dots update` does. A checkout without main@origin, as in CI,
# skips the tracking. A read-only checkout, such as the one the Lima VM
# mounts, stays as it is.
if [[ ! -d .jj && -w . ]] && command -v jj >/dev/null; then
  jj git init --colocate
  jj bookmark track main@origin 2>/dev/null || true
fi

if [[ "$desktop" == true && "$(uname -s)" == Darwin ]]; then
  setup/onchange macos-defaults setup/macos-defaults -- setup/macos-defaults

  # ssh, git signing, and WezTerm find the 1Password agent at the Linux
  # path, so one path serves both systems.
  mkdir -p ~/.1password
  ln -sfn ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock \
    ~/.1password/agent.sock
fi

# Docker clients reach podman through its user socket, which hooks.fish
# exports as DOCKER_HOST.
if [[ "$(uname -s)" == Linux ]] && command -v podman >/dev/null; then
  systemctl --user enable --now podman.socket ||
    echo "warning: podman.socket not enabled; docker clients can't reach podman" >&2
fi

# On macOS the helper links /var/run/docker.sock to the machine's socket
# at each `podman machine start`, so Docker clients need no DOCKER_HOST.
helper_plist="/Library/LaunchDaemons/com.github.containers.podman.helper-$USER.plist"
if [[ "$(uname -s)" == Darwin && ! -f "$helper_plist" ]] && command -v podman-mac-helper >/dev/null; then
  sudo podman-mac-helper install ||
    echo "warning: podman-mac-helper not installed; docker clients can't reach podman" >&2
fi

# Clones the template repos the tinty config names, then applies the last
# scheme, or the default one on a fresh machine.
setup/onchange tinty modules/core/.config/tinted-theming/tinty/config.toml -- \
  sh -c 'tinty sync && tinty init'

# zoxide learns a directory only from a cd. The seed adds every repo and
# every directory in atuin's history, so a fresh clone is jumpable before
# the first visit.
if command -v zoxide >/dev/null && command -v fish >/dev/null; then
  setup/zoxide-seed
fi

# $SHELL belongs to the calling process, so read the account's login shell.
fish="$(command -v fish)"
case "$(uname -s)" in
Darwin) login_shell="$(dscl . -read ~ UserShell | cut -d' ' -f2)" ;;
*) login_shell="$(getent passwd "$USER" | cut -d: -f7)" ;;
esac
if [[ "$fish" != "$login_shell" ]]; then
  if ! grep -qxF "$fish" /etc/shells; then
    echo "$fish" | sudo tee -a /etc/shells >/dev/null
  fi
  case "$(uname -s)" in
  Darwin) chsh -s "$fish" || echo "  ! Run manually: chsh -s $fish" ;;
  *) sudo usermod -s "$fish" "$(whoami)" || echo "  ! Run manually: chsh -s $fish" ;;
  esac
fi
