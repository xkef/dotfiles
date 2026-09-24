function eza --description "eza with group-directories-first and file links"
    # Names link to their files over OSC 8, for a terminal only, and WezTerm
    # opens them in Neovim.
    set -l links
    isatty stdout; and set links --hyperlink
    command eza --group-directories-first $links $argv
end
