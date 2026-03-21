# .zshrc — sourced for INTERACTIVE shells only (after .zshenv and .zprofile).
# All interactive config lives in conf.d/*.zsh files, sourced in order.
# See: man zsh "STARTUP/SHUTDOWN FILES"

# ── Profiling (ZPROFRC=1 zsh) ────────────────────────
# Start zsh with ZPROFRC=1 to get a breakdown of startup time by function.
# Uses zsh/zprof module: https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzprof-Module
[[ -n "$ZPROFRC" ]] && zmodload zsh/zprof

# Source all config files from conf.d/ in lexical order (00, 01, 02, ...).
# Each file is auto-compiled to .zwc bytecode for faster sourcing (~2x).
# The (N) glob qualifier suppresses errors if no files match.
# See: man zshexpn "GLOB QUALIFIERS"
for f in "$ZDOTDIR"/conf.d/*.zsh(N); do
  [[ ! -f "$f.zwc" || "$f" -nt "$f.zwc" ]] && zcompile "$f" &>/dev/null
  source "$f"
done

# ── Local overrides ──────────────────────────────────
# Machine-specific config that shouldn't be committed (e.g., work credentials).
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"

# ── Profiling output ────────────────────────────────
[[ -n "$ZPROFRC" ]] && zprof
