#!/usr/bin/env bash
# Download pre-built binaries to ~/.local/bin on Linux systems
# without a package manager. Skips tools already on PATH.
set -uo pipefail

BIN="$HOME/.local/bin"
mkdir -p "$BIN"
export PATH="$BIN:$PATH"

SKIP=(stow git curl zsh tmux jdtls)

log()  { printf '  %s\n' "$1"; }
has()  { command -v "$1" &>/dev/null; }

latest_tag() {
    local repo=$1
    local response
    response=$(curl -sL "https://api.github.com/repos/$repo/releases/latest") || {
        log "    ! failed to reach GitHub API for $repo"
        return 1
    }
    local tag
    tag=$(printf '%s' "$response" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
    if [[ -z "$tag" ]]; then
        log "    ! no release tag found for $repo (rate-limited?)"
        return 1
    fi
    printf '%s' "$tag"
}

ARCH=$(uname -m)

install_bin() {
    local name=$1; shift
    if has "$name"; then return 0; fi
    log "Installing $name..."
    local output
    if output=$("$@" 2>&1); then
        return 0
    fi
    log "  ! $name: install failed"
    if [[ -n "$output" ]]; then
        printf '%s\n' "$output" | tail -10 | while IFS= read -r line; do
            log "    | $line"
        done
    fi
}

# Download a tarball from a GitHub release containing a single binary.
#   github_bin <repo> <arch> <asset> <bin_in_archive>
# All args are fully resolved (no templates).
github_bin() {
    local repo=$1 a=$2 asset=$3 bin_path=$4
    local tag; tag=$(latest_tag "$repo") || return 1
    local v=${tag#v}
    # Expand tag/version in asset and bin_path
    asset=${asset/TAG/$tag}; asset=${asset/VER/$v}; asset=${asset/ARCH/$a}
    bin_path=${bin_path/TAG/$tag}; bin_path=${bin_path/VER/$v}; bin_path=${bin_path/ARCH/$a}
    curl -fsSL "https://github.com/$repo/releases/download/$tag/$asset" | tar -xzf - -C /tmp
    cp "/tmp/$bin_path" "$BIN/"
    local dir=${bin_path%/*}
    [[ "$dir" != "$bin_path" ]] && rm -rf "/tmp/$dir" || rm -f "/tmp/$bin_path"
}

# Arch mapping helpers
linux_arch()  { case $ARCH in arm64) echo aarch64 ;; *) echo "$ARCH" ;; esac; }
go_arch()     { case $ARCH in x86_64) echo amd64 ;; aarch64) echo arm64 ;; *) echo "$ARCH" ;; esac; }

# --- main ---

missing=()
for cmd in "${SKIP[@]}"; do
    has "$cmd" || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
    log "Skipping (need system package manager): ${missing[*]}"
fi

install_bin nvim  bash -c "
    mkdir -p \$HOME/.local
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$(go_arch).tar.gz \
        | tar -xzf - -C \$HOME/.local --strip-components=1"

install_bin eza   bash -c \
    "curl -fsSL https://github.com/eza-community/eza/releases/latest/download/eza_$(linux_arch)-unknown-linux-gnu.tar.gz \
        | tar -xzf - -C '$BIN'"

install_bin bat    github_bin sharkdp/bat         "$(linux_arch)" "bat-TAG-ARCH-unknown-linux-gnu.tar.gz"      "bat-TAG-ARCH-unknown-linux-gnu/bat"
install_bin fd     github_bin sharkdp/fd          "$(linux_arch)" "fd-TAG-ARCH-unknown-linux-gnu.tar.gz"       "fd-TAG-ARCH-unknown-linux-gnu/fd"
install_bin rg     github_bin BurntSushi/ripgrep   "$(linux_arch)" "ripgrep-TAG-ARCH-unknown-linux-gnu.tar.gz"  "ripgrep-TAG-ARCH-unknown-linux-gnu/rg"
install_bin delta  github_bin dandavison/delta     "$(linux_arch)" "delta-TAG-ARCH-unknown-linux-gnu.tar.gz"    "delta-TAG-ARCH-unknown-linux-gnu/delta"
install_bin lazygit github_bin jesseduffield/lazygit "$(go_arch)"  "lazygit_VER_Linux_ARCH.tar.gz"              "lazygit"
install_bin fzf    github_bin junegunn/fzf         "$(go_arch)"   "fzf-VER-linux_ARCH.tar.gz"                  "fzf"

install_bin jq     bash -c \
    "curl -fsSL -o '$BIN/jq' https://github.com/jqlang/jq/releases/latest/download/jq-linux-$(go_arch) && chmod +x '$BIN/jq'"

install_bin zoxide   bash -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
install_bin starship bash -c "curl -sS https://starship.rs/install.sh | sh -s -- -y -b '$BIN'"
install_bin ghostty  bash -c 'curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash'
install_bin atuin    bash -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
