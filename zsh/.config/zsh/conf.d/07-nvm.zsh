# ── nvm (lazy-loaded) ────────────────────────────────
# nvm.sh is ~5000 lines of bash; sourcing it costs ~80-200ms.
# Stub functions defer the cost to first use of nvm/node/npm/npx.
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"

# Find nvm.sh: XDG location, ~/.nvm, or Homebrew
_nvm_script="$NVM_DIR/nvm.sh"
[[ -s "$_nvm_script" ]] || _nvm_script="$HOME/.nvm/nvm.sh"
[[ -s "$_nvm_script" ]] || _nvm_script="/opt/homebrew/opt/nvm/nvm.sh"

if [[ -s "$_nvm_script" ]]; then
  _nvm_load() {
    unfunction nvm node npm npx _nvm_load 2>/dev/null
    source "$_nvm_script"
    unset _nvm_script
  }
  nvm()  { _nvm_load; nvm "$@" }
  node() { _nvm_load; node "$@" }
  npm()  { _nvm_load; npm "$@" }
  npx()  { _nvm_load; npx "$@" }
else
  unset _nvm_script
fi
