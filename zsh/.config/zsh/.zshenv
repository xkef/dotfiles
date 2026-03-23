# When ZDOTDIR is inherited (e.g., inside tmux), zsh reads this file
# instead of ~/.zshenv. Source the canonical .zshenv so all exports
# (PATH, GITHUB_TOKEN, etc.) are still set.
# See: man zsh "STARTUP/SHUTDOWN FILES"
source "$HOME/.zshenv"
