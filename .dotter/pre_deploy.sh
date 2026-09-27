#!/usr/bin/env bash
# Installs the packages before the files deploy, when a package list
# changed. Dotter renders this file with Handlebars and runs it from the
# repo root.
set -euo pipefail

# On a fresh Mac the calling shell predates Homebrew. Put the install
# prefixes first so later steps find the tools the packages step installs.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# A partial install, EX_TEMPFAIL from sysexits.h, lets the deploy go on.
# It records no stamp, so the next deploy retries the failed packages. The
# stamp name holds the desktop selection, so selecting desktop installs its
# apps even when no package list changed.
readonly EX_TEMPFAIL=75
export DOTFILES_DESKTOP="{{#if dotter.packages.desktop}}true{{else}}false{{/if}}"
status=0
setup/onchange "packages-desktop-$DOTFILES_DESKTOP" setup/packages/install setup/packages/*/* -- \
  setup/packages/install || status=$?
if ((status != 0 && status != EX_TEMPFAIL)); then
  exit "$status"
fi
