#!/usr/bin/env bash
# Installs the packages before the files deploy, when a package list
# changed. Dotter renders this file with Handlebars and runs it from the
# repo root.
set -euo pipefail

# On a fresh Mac the calling shell predates Homebrew. Put the install
# prefixes first so later steps find the tools the packages step installs.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# A fresh machine has no fish environment yet. Tools such as brew fall back
# to ~/Library/Application Support on macOS without it.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# A partial install, EX_TEMPFAIL from sysexits.h, lets the deploy go on.
# It records no stamp, so the next deploy retries the failed packages. The
# stamp name holds the package selection, so selecting another package
# installs its list even when no list changed. dotter.packages also holds
# the unselected packages, set to false. The stamp hashes only this
# system's lists for the selected packages.
readonly EX_TEMPFAIL=75
export DOTFILES_PACKAGES="{{#each dotter.packages}}{{#if this}}{{@key}} {{/if}}{{/each}}"
os=arch
if [[ "$(uname -s)" == Darwin ]]; then
  os=macos
fi
shopt -s nullglob
lists=()
for package in $DOTFILES_PACKAGES; do
  lists+=(setup/packages/"$os"/"$package".*)
done
status=0
setup/onchange "packages-${DOTFILES_PACKAGES// /-}" setup/packages/install "${lists[@]}" -- \
  setup/packages/install || status=$?
if ((status != 0 && status != EX_TEMPFAIL)); then
  exit "$status"
fi
