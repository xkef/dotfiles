status is-interactive; or return

# ── Line editing (built-in) ───────────────────────────
# fish defaults, listed here for the keys reference.
# @key shell :: Ctrl-A / E :: Beginning / end of line
# @key shell :: Alt-F / B :: Forward / backward one word
# @key shell :: Ctrl-W :: Delete word backward
# @key shell :: Alt-D :: Delete word forward
# @key shell :: Ctrl-K :: Kill to end of line
# @key shell :: Ctrl-U :: Kill entire line
# @key shell :: Ctrl-Y :: Yank last killed text
# @key shell :: Ctrl-P / N :: Prefix history search (also arrows)
# @key shell :: Alt-H :: Context-aware man page (run-help)
# @key shell :: Alt-. :: Insert last argument
# @key shell :: Alt-S :: Prepend sudo

# ── Custom keybindings ───────────────────────────────
# @key shell :: Ctrl-R :: Atuin history search

# @key shell :: Ctrl-T :: Pick for the current command (tv)
# @key shell :: Alt-C :: Directory jump under cwd (tv)
# @key shell :: Alt-Z :: Jump to visited directory (tv + zoxide)
# @key shell :: Alt-/ :: Grep file contents (tv)
# television.fish binds these.

# @key shell :: Ctrl-X Ctrl-E :: Edit command in nvim
bind \cx\ce edit_command_buffer
# @key shell :: Ctrl-Z :: Toggle fg/bg (undo if no jobs)
bind \cz __fg_bg_toggle
# @key shell :: Alt-, :: Cycle earlier arguments
bind \e, history-token-search-forward
# @key shell :: Ctrl-S :: Yazi file manager (cd-on-quit)
bind \cs __yazi_cd
