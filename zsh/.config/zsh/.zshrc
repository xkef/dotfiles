# ── Profiling (ZPROFRC=1 zsh) ────────────────────────
[[ -n "$ZPROFRC" ]] && zmodload zsh/zprof

# Source all config files from conf.d/ (in order)
# zsh automatically uses .zwc bytecode if it exists and is newer than .zsh
for f in "$ZDOTDIR"/conf.d/*.zsh(N); do
  [[ ! -f "$f.zwc" || "$f" -nt "$f.zwc" ]] && zcompile "$f" &>/dev/null
  source "$f"
done

# ── Local overrides ──────────────────────────────────
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── Profiling output ────────────────────────────────
[[ -n "$ZPROFRC" ]] && zprof
