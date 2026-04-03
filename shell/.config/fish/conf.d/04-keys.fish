# ── Line editing (built-in) ───────────────────────────
# These are fish/readline defaults, documented here for the keys reference.
# @key shell :: Ctrl-A / E :: Beginning / end of line
# @key shell :: Alt-F / B :: Forward / backward one word
# @key shell :: Ctrl-W :: Delete word backward
# @key shell :: Alt-D :: Delete word forward
# @key shell :: Ctrl-K :: Kill to end of line
# @key shell :: Ctrl-U :: Kill entire line
# @key shell :: Ctrl-Y :: Yank last killed text

# ── Custom keybindings ───────────────────────────────
# @key shell :: Ctrl-R :: Atuin history search
# @key shell :: Ctrl-G :: Navi cheatsheets
# @key shell :: Ctrl-P / N :: Prefix history search (also arrows)
bind \cp up-or-search
bind \cn down-or-search

# @key shell :: Ctrl-T :: File search (fzf)
# @key shell :: Alt-C :: Directory jump under cwd (fzf + fd)
# (bound by fzf --fish in 05-fzf.fish)

# @key shell :: Alt-Z :: Jump to visited directory (fzf+zoxide)
# @key shell :: Alt-/ :: Live grep file contents (rg + fzf)
# @key shell :: Alt-T :: Television smart picker
# (bound in 05-fzf.fish)

# @key shell :: Ctrl-S :: Yazi file manager (cd-on-quit)
bind \cs __yazi_cd
# @key shell :: Ctrl-X Ctrl-E :: Edit command in nvim
bind \cx\ce edit_command_buffer
# @key shell :: Ctrl-Z :: Toggle fg/bg (undo if no jobs)
bind \cz __fg_bg_toggle
# @key shell :: Alt-H :: Context-aware man page (run-help)
bind \eh __fish_man_page
# @key shell :: Alt-. :: Insert last argument
bind \e. history-token-search-backward
# @key shell :: Alt-, :: Cycle earlier arguments
bind \e, history-token-search-forward
# @key shell :: Esc Esc :: Prepend sudo
bind \e\e __fish_toggle_sudo
