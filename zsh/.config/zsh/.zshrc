# Source all config files from conf.d/ (in order)
for f in "$ZDOTDIR"/conf.d/*.zsh(N); do
  source "$f"
done

# ── Local overrides ──────────────────────────────────
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
