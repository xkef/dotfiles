#!/usr/bin/env bash
# Setup that depends on the deployed files. Dotter renders this file with
# Handlebars and runs it from the repo root.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# The selected dotter packages. The quotes keep the Handlebars valid bash.
agents="{{#if dotter.packages.agents}}true{{/if}}"
desktop="{{#if dotter.packages.desktop}}true{{/if}}"

chmod 700 ~/.ssh

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

# Files that setup/identity/render wrote before private/ replaced it. jj
# still reads work.toml from conf.d.
rm -f ~/.config/git/config.personal ~/.config/git/config.work \
  ~/.config/git/config.secondary ~/.config/git/config.secondary-remotes \
  ~/.config/jj/conf.d/work.toml

setup/private/decrypt

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
fi

# vale finds its global config through XDG_CONFIG_HOME, which defaults to
# ~/Library/Application Support on macOS. A fresh machine has no fish
# environment that sets it yet.
setup/onchange vale-sync modules/core/.config/vale/.vale.ini -- \
  env VALE_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/vale/.vale.ini" vale sync

# Clones the template repos the tinty config names, then applies the last
# scheme, or the default one on a fresh machine.
setup/onchange tinty modules/core/.config/tinted-theming/tinty/config.toml -- \
  sh -c 'tinty sync && tinty init'

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
