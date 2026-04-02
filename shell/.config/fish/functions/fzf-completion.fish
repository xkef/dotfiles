function fzf-completion --description 'fzf tab completion (single-select)'
    set -l tokens (__fzf_cmd_tokens)
    set -l current_token (commandline -t)
    set -l cmd_name $tokens[1]

    if test -n "$tokens"; and functions -q _fzf_complete_$cmd_name
        _fzf_complete_$cmd_name $tokens
    else
        set -l fzf_opt --query=$current_token
        __fzf_complete_native "$tokens $current_token" $fzf_opt
    end
end
