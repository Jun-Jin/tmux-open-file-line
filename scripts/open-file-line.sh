#!/bin/sh
#
# tmux-open-file-line handler
#
# tmux の M-MouseDown1Pane (@open-file-line-key) から呼ばれ、クリック位置の
# path:line をエディタの新規 window で開く
#   $1: #{mouse_word}  $2: #{pane_current_path}  $3: #{mouse_line} (フォールバック用)
#   $4: #{pane_current_command} (エディタペイン内での誤爆ガード用)
#
# 各引数の先頭の x は番兵: #{q:...} は空文字だと引数ごと消えて以降がズレるため、
# 必ず 1 文字残して位置を固定する (open-file-line.tmux 側で付与)
#
# エディタは @open-file-line-editor (または環境変数 TMUX_OPEN_EDITOR) で指定。
# デフォルト vim。+行番号 を解釈できる vim 系コマンド前提

get_option() {
    v=$(tmux show-option -gqv "$1" 2>/dev/null)
    if [ -n "$v" ]; then
        printf '%s' "$v"
    else
        printf '%s' "$2"
    fi
}

default_md_cmd=""
[ "$(uname -s)" = Darwin ] && default_md_cmd=open

EDITOR_CMD=${TMUX_OPEN_EDITOR:-$(get_option "@open-file-line-editor" vim)}
MD_CMD=$(get_option "@open-file-line-markdown-cmd" "$default_md_cmd")
DEBUG=$(get_option "@open-file-line-debug" off)

# 番兵文字 x を剥がす
word=${1#x}
dir=${2#x}
line_text=${3#x}
cmd=${4#x}

# デバッグ用: 最後の呼び出し引数を残す (クリックしても開かない時はここを見る)
if [ "$DEBUG" = on ]; then
    printf 'word=[%s]\ndir=[%s]\nline=[%s]\ncmd=[%s]\n' "$word" "$dir" "$line_text" "$cmd" \
        > /tmp/tmux-open-file-line.last
fi

# エディタペイン内でのクリックは無視
editor_bin=${EDITOR_CMD%% *}
case $cmd in
"$editor_bin" | nvim | vim | vi) exit 0 ;;
esac

LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LC_ALL

try_open() {
    w=$1
    case $w in
    *:[0-9]*)
        f=${w%%:*}
        r=${w#*:}
        l=${r%%:*}
        ;;
    *)
        f=$w
        l=1
        ;;
    esac
    case $f in
    "~/"*) f=$HOME/${f#"~/"} ;;
    esac
    case $f in
    /*) ;;
    *) f=$dir/$f ;;
    esac
    [ -f "$f" ] || return 1
    if [ -n "$MD_CMD" ]; then
        case $f in
        *.md) exec $MD_CMD -- "$f" ;;
        esac
    fi
    exec tmux new-window -a -c "$dir" "$EDITOR_CMD +$l -- '$f'"
}

# trim
word=$(printf '%s' "$word" | sed -E "s/^[\`\"'(\[<（【「]+//; s/[^A-Za-z0-9_~]+\$//")
if [ -n "$word" ]; then
    try_open "$word"
fi

# fallback: 行全体から path っぽいトークンを拾う
for cand in $(printf '%s' "$line_text" | LC_ALL=C tr -c 'A-Za-z0-9_./:~-' ' '); do
    case $cand in
    */* | *.*) try_open "$cand" ;;
    esac
done

exit 0
