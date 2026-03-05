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

map_arch() {
    local from=$1 to=$2
    if [[ "$ARCH" == "$from" ]]; then echo "$to"; else echo "$ARCH"; fi
}

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

# Download a binary from a GitHub release tarball.
#   github_release <repo> <asset_pattern> <bin_in_archive> [arch_from:arch_to]
# Patterns use {tag}, {version}, {arch}. The arch mapping is optional.
github_release() {
    local repo=$1 asset_pat=$2 bin_pat=$3
    local from="" to=""
    if [[ -n "${4:-}" ]]; then
        from=${4%%:*}; to=${4##*:}
    fi

    local a=$ARCH
    [[ -n "$from" && "$a" == "$from" ]] && a=$to
    local tag; tag=$(latest_tag "$repo") || return 1
    local version=${tag#v}
    local asset=${asset_pat//\{tag\}/$tag}
    asset=${asset//\{version\}/$version}
    asset=${asset//\{arch\}/$a}
    local bin_path=${bin_pat//\{tag\}/$tag}
    bin_path=${bin_path//\{version\}/$version}
    bin_path=${bin_path//\{arch\}/$a}
    local url="https://github.com/${repo}/releases/download/${tag}/${asset}"

    curl -fsSL "$url" | tar -xzf - -C /tmp
    cp "/tmp/${bin_path}" "$BIN/"
    local dir=${bin_path%/*}
    if [[ "$dir" != "$bin_path" ]]; then
        rm -rf "/tmp/${dir}"
    else
        rm -f "/tmp/${bin_path}"
    fi
}

# --- individual installers ---

do_nvim() {
    local a; a=$(map_arch aarch64 arm64)
    mkdir -p "$HOME/.local"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${a}.tar.gz" \
        | tar -xzf - -C "$HOME/.local" --strip-components=1
}

do_eza() {
    local a; a=$(map_arch arm64 aarch64)
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${a}-unknown-linux-gnu.tar.gz" \
        | tar -xzf - -C "$BIN"
}

do_fzf() {
    local a=$ARCH
    case "$a" in x86_64) a=amd64 ;; aarch64) a=arm64 ;; esac
    local tag; tag=$(latest_tag junegunn/fzf) || return 1
    local v=${tag#v}
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${v}-linux_${a}.tar.gz" \
        | tar -xzf - -C "$BIN" fzf
}

do_jq() {
    local a=$ARCH
    case "$a" in x86_64) a=amd64 ;; aarch64) a=arm64 ;; esac
    curl -fsSL -o "$BIN/jq" "https://github.com/jqlang/jq/releases/latest/download/jq-linux-${a}"
    chmod +x "$BIN/jq"
}

# --- main ---

missing=()
for cmd in "${SKIP[@]}"; do
    has "$cmd" || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
    log "Skipping (need system package manager): ${missing[*]}"
fi

install_bin nvim     do_nvim
install_bin eza      do_eza
install_bin bat      github_release sharkdp/bat      "bat-{tag}-{arch}-unknown-linux-gnu.tar.gz"      "bat-{tag}-{arch}-unknown-linux-gnu/bat"      arm64:aarch64
install_bin fd       github_release sharkdp/fd       "fd-{tag}-{arch}-unknown-linux-gnu.tar.gz"       "fd-{tag}-{arch}-unknown-linux-gnu/fd"        arm64:aarch64
install_bin rg       github_release BurntSushi/ripgrep "ripgrep-{tag}-{arch}-unknown-linux-gnu.tar.gz" "ripgrep-{tag}-{arch}-unknown-linux-gnu/rg"   arm64:aarch64
install_bin delta    github_release dandavison/delta  "delta-{tag}-{arch}-unknown-linux-gnu.tar.gz"    "delta-{tag}-{arch}-unknown-linux-gnu/delta"  arm64:aarch64
install_bin lazygit  github_release jesseduffield/lazygit "lazygit_{version}_Linux_{arch}.tar.gz"      "lazygit"                                    aarch64:arm64
install_bin fzf      do_fzf
install_bin zoxide   bash -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
install_bin jq       do_jq
install_bin starship bash -c "curl -sS https://starship.rs/install.sh | sh -s -- -y -b '$BIN'"
install_bin ghostty  bash -c 'curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh | bash'
install_bin atuin    bash -c "curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh"
