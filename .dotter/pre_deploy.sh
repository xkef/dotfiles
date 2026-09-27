#!/usr/bin/env bash
# Installs the packages before the files deploy, when a package list
# changed. Dotter runs this from the repo root.
set -euo pipefail

# On a fresh Mac the calling shell predates Homebrew. Put the install
# prefixes first so later steps find the tools the packages step installs.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# A partial install, EX_TEMPFAIL from sysexits.h, lets the deploy go on.
# It records no stamp, so the next deploy retries the failed packages.
readonly EX_TEMPFAIL=75
status=0
setup/onchange packages setup/packages/install setup/packages/*/* -- setup/packages/install ||
  status=$?
if ((status != 0 && status != EX_TEMPFAIL)); then
  exit "$status"
fi
