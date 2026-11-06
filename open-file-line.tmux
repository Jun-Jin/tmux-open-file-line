#!/usr/bin/env bash
#
# tmux-open-file-line - TPM entry point
#
# Binds Alt+Click (configurable) so that clicking a `path:line` token in a
# pane opens that file at that line in your editor, in a new tmux window.
#
# Options (set in tmux.conf before `run '~/.tmux/plugins/tpm/tpm'`):
#   set -g @open-file-line-editor 'nvim'              # default: vim
#   set -g @open-file-line-key    'M-MouseDown1Pane'  # default: M-MouseDown1Pane
#   set -g @open-file-line-word-separators ' '        # default: ' ' ; 'off' leaves word-separators untouched
#   set -g @open-file-line-markdown-cmd 'open'        # default: 'open' on macOS, '' (use editor) elsewhere
#   set -g @open-file-line-debug 'on'                 # default: off ; logs last args to /tmp/tmux-open-file-line.last

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CURRENT_DIR/scripts/open-file-line.sh"

get_option() {
    local value
    value="$(tmux show-option -gqv "$1")"
    if [ -z "$value" ]; then
        echo "$2"
    else
        echo "$value"
    fi
}

key="$(get_option "@open-file-line-key" "M-MouseDown1Pane")"
word_separators="$(get_option "@open-file-line-word-separators" " ")"

# #{q:...} drops the whole argument when the value is empty, which shifts the
# remaining positional parameters. Prefix every argument with a sentinel "x"
# so each one is always present; the script strips it again.
handler="'$SCRIPT' x#{q:mouse_word} x#{q:pane_current_path} x#{q:mouse_line} x#{q:pane_current_command}"

tmux bind-key -n              "$key" run-shell "$handler"
tmux bind-key -T copy-mode    "$key" run-shell "$handler"
tmux bind-key -T copy-mode-vi "$key" run-shell "$handler"

# mouse_word honours word-separators; the tmux default splits on "/" ":" "."
# so a clicked path:line would only yield a fragment. Use a space-only
# separator unless the user opted out.
if [ "$word_separators" != "off" ]; then
    tmux set-option -g word-separators "$word_separators"
fi
