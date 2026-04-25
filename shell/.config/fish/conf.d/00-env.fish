# ── XDG Base Directories ─────────────────────────────
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state
set -gx XDG_CACHE_HOME $HOME/.cache

# ── Homebrew ─────────────────────────────────────────
if test -d /opt/homebrew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    set -gx MANPATH /opt/homebrew/share/man $MANPATH
    set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
end

# ── Editor ───────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx NVIM_APPNAME lazyvim

if command -q nvim
    set -gx MANPAGER 'nvim +Man!'
    set -gx MANWIDTH 999
end

# ── XDG tool homes ──────────────────────────────────
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOBIN $GOPATH/bin
set -gx LESSHISTFILE $XDG_STATE_HOME/less/history
set -gx NODE_REPL_HISTORY $XDG_DATA_HOME/node_repl_history
set -gx _ZO_EXCLUDE_DIRS "$HOME/Library/*:$HOME/.Trash/*:/tmp/*"

# ── Pager ────────────────────────────────────────────
set -gx PAGER less
set -gx LESS '-iFMRX --mouse -#.25'

# ── Mise ─────────────────────────────────────────────
# Disable Homebrew's vendor mise-activate.fish (~26ms). We add shims
# to PATH directly in 03-tools.fish instead.
set -gx MISE_ACTIVATE_AGGRESSIVE 0
set -gx MISE_FISH_AUTO_ACTIVATE 0

# ── Dotfiles directory ───────────────────────────────
if test -z "$DOTFILES_DIR" -a -f $HOME/.config/dotfiles/dir
    set -gx DOTFILES_DIR (cat $HOME/.config/dotfiles/dir)
end

# ── PATH ─────────────────────────────────────────────
fish_add_path -gP $HOME/.local/bin
fish_add_path -gP $CARGO_HOME/bin
fish_add_path -gP $GOPATH/bin
if set -q HOMEBREW_PREFIX
    fish_add_path -gP $HOMEBREW_PREFIX/bin
    fish_add_path -gP $HOMEBREW_PREFIX/sbin
end
fish_add_path -gP /usr/local/bin

# ── 1Password SSH agent ──────────────────────────────
# git signing uses `ssh-keygen -Y sign`, which reads $SSH_AUTH_SOCK
# directly and ignores ssh_config's IdentityAgent. Point at the
# 1Password socket so signing reaches the same key ssh does.
# Skip when SSH'd in to preserve a forwarded agent.
if not set -q SSH_CONNECTION
    set -l _op_sock
    switch (uname -s)
        case Darwin
            set _op_sock "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        case Linux
            set _op_sock "$HOME/.1password/agent.sock"
    end
    if test -S "$_op_sock"
        set -gx SSH_AUTH_SOCK "$_op_sock"
    end
end

# ── GitHub token ─────────────────────────────────────
if test -z "$GITHUB_TOKEN"; and command -q gh
    set -gx GITHUB_TOKEN (gh auth token 2>/dev/null)
end
