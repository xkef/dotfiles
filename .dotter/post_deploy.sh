#!/usr/bin/env bash
# Setup that depends on the deployed files. Dotter renders this file with
# Handlebars and runs it from the repo root.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

chmod 700 ~/.ssh

# Claude Code reads the shared skills through ~/.claude/skills. Dotter
# links files, not directories, so the directory link lives here.
if [[ -L ~/.claude/skills || ! -e ~/.claude/skills ]]; then
  ln -sfn ~/.agents/skills ~/.claude/skills
else
  echo "warning: ~/.claude/skills is a directory; move it and deploy again" >&2
fi

# Dotter fills in the `work` variable from the local config.
setup/identity/render "{{work}}"

if [[ "$(uname -s)" == Darwin ]]; then
  setup/onchange macos-defaults setup/macos-defaults -- setup/macos-defaults
fi

# vale finds its global config through XDG_CONFIG_HOME, which defaults to
# ~/Library/Application Support on macOS. A fresh machine has no fish
# environment that sets it yet.
setup/onchange vale-sync home/tools/vale/.vale.ini -- \
  env VALE_CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/vale/.vale.ini" vale sync

# Clones the template repos the tinty config names, then applies the last
# scheme, or the default one on a fresh machine.
setup/onchange tinty home/theme/tinted-theming/tinty/config.toml -- \
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
