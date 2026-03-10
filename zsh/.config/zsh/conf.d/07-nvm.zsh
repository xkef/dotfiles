# ── nvm (lazy-loaded) ────────────────────────────────
# nvm.sh is ~5000 lines of bash; sourcing it costs ~80-200ms.
# Stub functions defer the cost to first use of nvm/node/npm/npx.
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_load() {
    unfunction nvm node npm npx 2>/dev/null
    source "$NVM_DIR/nvm.sh"
    source "$NVM_DIR/bash_completion" 2>/dev/null
  }
  nvm()  { _nvm_load; nvm "$@" }
  node() { _nvm_load; node "$@" }
  npm()  { _nvm_load; npm "$@" }
  npx()  { _nvm_load; npx "$@" }
fi
