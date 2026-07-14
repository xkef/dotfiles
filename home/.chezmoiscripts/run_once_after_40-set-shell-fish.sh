#!/bin/bash
set -euo pipefail
fish="$(command -v fish 2>/dev/null || true)"
[[ -z "$fish" || "$fish" == "${SHELL:-}" ]] && exit 0
if [[ -f /etc/shells ]] && ! grep -qxF "$fish" /etc/shells; then
  echo "$fish" | sudo tee -a /etc/shells >/dev/null
fi
case "$(uname -s)" in
Darwin)
  chsh -s "$fish" || echo "  ! Run manually: chsh -s $fish"
  ;;
*)
  sudo usermod -s "$fish" "$(whoami)" || echo "  ! Run manually: chsh -s $fish"
  ;;
esac
