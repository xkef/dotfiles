# Theme adapter (vcs package): regenerate delta's palette-derived include.
# ~/.config/git/config includes delta.gitconfig (untracked, gitignored).
# Sourced by `theme` with $t_palette/$t_bg set; uses the _blend_hex helper.
set -l delta_red $t_palette[2]
set -l delta_green $t_palette[3]
set -l delta_dim $t_palette[9]
set -l delta_minus_bg (_blend_hex $t_bg $delta_red 15)
set -l delta_minus_emph (_blend_hex $t_bg $delta_red 30)
set -l delta_plus_bg (_blend_hex $t_bg $delta_green 15)
set -l delta_plus_emph (_blend_hex $t_bg $delta_green 30)

set -l delta_conf (set -q XDG_CONFIG_HOME && echo $XDG_CONFIG_HOME || echo $HOME/.config)/git/delta.gitconfig
printf '[delta]
\tsyntax-theme = ansi
\tminus-style = syntax "#%s"
\tminus-emph-style = syntax "#%s"
\tminus-empty-line-marker-style = syntax "#%s"
\tplus-style = syntax "#%s"
\tplus-emph-style = syntax "#%s"
\tplus-empty-line-marker-style = syntax "#%s"
\tline-numbers-minus-style = "#%s"
\tline-numbers-plus-style = "#%s"
\tline-numbers-zero-style = "#%s"
' $delta_minus_bg $delta_minus_emph $delta_minus_bg \
    $delta_plus_bg $delta_plus_emph $delta_plus_bg \
    $delta_red $delta_green $delta_dim >$delta_conf
