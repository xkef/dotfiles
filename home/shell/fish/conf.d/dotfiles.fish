# ── Dotfiles directory ───────────────────────────────
# Resolved through this file's symlink into the repo, so dots, sb, vm, and
# the LazyVim <leader>fC picker all agree on the repo path.
set -gx DOTFILES_DIR (string replace /home/shell/fish/conf.d/dotfiles.fish '' (path resolve (status filename)))
