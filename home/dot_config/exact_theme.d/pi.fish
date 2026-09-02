# Theme adapter (agent base): regenerate pi's palette-derived theme file.
# The tracked pi settings select the theme by name ("dots"), and pi watches
# the active custom theme file and reloads it on change — so rewriting this
# recolors running pi sessions, not just the next launch. The file is
# machine-local and untracked, like the delta adapter's include.
# Sourced by `theme` with $t_palette/$t_bg/$t_fg set; uses the _blend_hex
# helper.
set -l pi_agent_dir (set -q PI_CODING_AGENT_DIR && echo $PI_CODING_AGENT_DIR || echo $HOME/.pi/agent)
if test -d $pi_agent_dir
    set -l pi_red $t_palette[2]
    set -l pi_green $t_palette[3]
    set -l pi_yellow $t_palette[4]
    set -l pi_blue $t_palette[5]
    set -l pi_magenta $t_palette[6]
    set -l pi_cyan $t_palette[7]
    set -l pi_orange $t_palette[10]
    set -l pi_br_magenta $t_palette[14]
    set -l pi_br_cyan $t_palette[15]

    # Blend the grays toward the foreground rather than taking the ANSI
    # bright-black slot, so the ramp inverts by itself under light themes.
    set -l pi_gray (_blend_hex $t_bg $t_fg 60)
    set -l pi_dim_gray (_blend_hex $t_bg $t_fg 45)
    set -l pi_dark_gray (_blend_hex $t_bg $t_fg 30)

    # Message and tool-box backgrounds: a wash of one palette color over the
    # terminal background, matching how the delta adapter tints diff hunks.
    set -l pi_selected_bg (_blend_hex $t_bg $pi_cyan 24)
    set -l pi_search_bg (_blend_hex $t_bg $pi_yellow 28)
    set -l pi_user_bg (_blend_hex $t_bg $pi_blue 16)
    set -l pi_custom_bg (_blend_hex $t_bg $pi_magenta 15)
    set -l pi_pending_bg (_blend_hex $t_bg $pi_cyan 8)
    set -l pi_success_bg (_blend_hex $t_bg $pi_green 12)
    set -l pi_error_bg (_blend_hex $t_bg $pi_red 14)
    set -l pi_info_bg (_blend_hex $t_bg $pi_yellow 18)

    # pi requires all 51 mandatory tokens in every theme; the four optional
    # ones are set too so search matches and the scrollbar do not collapse
    # into selectedBg.
    set -l pi_tokens \
        accent:$pi_cyan \
        border:$pi_blue \
        borderAccent:$pi_br_cyan \
        borderMuted:$pi_dark_gray \
        success:$pi_green \
        error:$pi_red \
        warning:$pi_yellow \
        muted:$pi_gray \
        dim:$pi_dim_gray \
        text:$t_fg \
        thinkingText:$pi_dim_gray \
        selectedBg:$pi_selected_bg \
        scrollbarThumb:$pi_dark_gray \
        searchMatchBg:$pi_search_bg \
        searchMatchText:$t_fg \
        userMessageBg:$pi_user_bg \
        userMessageText:$t_fg \
        customMessageBg:$pi_custom_bg \
        customMessageText:$t_fg \
        customMessageLabel:$pi_magenta \
        toolPendingBg:$pi_pending_bg \
        toolSuccessBg:$pi_success_bg \
        toolErrorBg:$pi_error_bg \
        toolTitle:$pi_cyan \
        toolOutput:$pi_gray \
        mdHeading:$pi_yellow \
        mdLink:$pi_blue \
        mdLinkUrl:$pi_dim_gray \
        mdCode:$pi_cyan \
        mdCodeBlock:$t_fg \
        mdCodeBlockBorder:$pi_dark_gray \
        mdQuote:$pi_gray \
        mdQuoteBorder:$pi_magenta \
        mdHr:$pi_dark_gray \
        mdListBullet:$pi_cyan \
        toolDiffAdded:$pi_green \
        toolDiffRemoved:$pi_red \
        toolDiffContext:$pi_gray \
        syntaxComment:$pi_dim_gray \
        syntaxKeyword:$pi_magenta \
        syntaxFunction:$pi_blue \
        syntaxVariable:$t_fg \
        syntaxString:$pi_green \
        syntaxNumber:$pi_orange \
        syntaxType:$pi_yellow \
        syntaxOperator:$t_fg \
        syntaxPunctuation:$pi_gray \
        thinkingOff:$pi_dark_gray \
        thinkingMinimal:$pi_dim_gray \
        thinkingLow:$pi_blue \
        thinkingMedium:$pi_cyan \
        thinkingHigh:$pi_yellow \
        thinkingXhigh:$pi_magenta \
        thinkingMax:$pi_br_magenta \
        bashMode:$pi_green

    set -l pi_lines
    for pi_token in $pi_tokens
        set -l pi_kv (string split -m 1 : $pi_token)
        set -a pi_lines (printf '    "%s": "#%s"' $pi_kv[1] $pi_kv[2])
    end

    set -l pi_themes_dir $pi_agent_dir/themes
    command mkdir -p $pi_themes_dir
    begin
        printf '{\n'
        printf '  "$schema": "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json",\n'
        printf '  "name": "dots",\n'
        printf '  "colors": {\n'
        string join ,\n $pi_lines
        printf '  },\n'
        printf '  "export": {\n'
        printf '    "pageBg": "#%s",\n' $t_bg
        printf '    "cardBg": "#%s",\n' $pi_user_bg
        printf '    "infoBg": "#%s"\n' $pi_info_bg
        printf '  }\n'
        printf '}\n'
    end >$pi_themes_dir/dots.json
end
