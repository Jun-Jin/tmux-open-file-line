# tmux-open-file-line

Alt+Click a `path:line` token in any tmux pane (compiler errors, grep output,
stack traces, `git diff`, ...) and the file opens at that line in your editor,
in a new tmux window.

Works in normal panes and in copy mode.

A `path:start-stop` token (e.g. `src/app.sh:12-20`) opens the file at `start`
with lines `start` through `stop` already selected in linewise Visual mode.

## Requirements

- tmux 3.x with `set -g mouse on`
- A vim-style editor that understands `+LINE` (vim, nvim, vi, ...). Range
  selection additionally relies on `-c {cmd}`.

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm)

Add to `tmux.conf`:

```tmux
set -g @plugin 'jun-jin/tmux-open-file-line'
```

Then press `prefix + I` to fetch and load the plugin.

### Manual

```sh
git clone https://github.com/jun-jin/tmux-open-file-line ~/.tmux/plugins/tmux-open-file-line
```

and add to `tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-open-file-line/open-file-line.tmux
```

## Configuration

All options are optional. Set them in `tmux.conf` **before** the line that
runs TPM (or the manual `run-shell`).

| Option | Default | Description |
| --- | --- | --- |
| `@open-file-line-editor` | `vim` | Editor command. Must accept `+LINE file`. |
| `@open-file-line-key` | `M-MouseDown1Pane` | Mouse binding (Alt+Left click). |
| `@open-file-line-word-separators` | `' '` | Value applied to tmux's `word-separators` so a whole `path:line` token is picked up. Set to `off` to leave `word-separators` alone. |
| `@open-file-line-range-select` | `on` | For `path:start-stop` tokens, select `start`..`stop` in Visual Line mode after opening. Set to `off` to only jump to `start`. |
| `@open-file-line-markdown-cmd` | `open` on macOS, empty elsewhere | Command used for `.md` files instead of the editor. Empty means use the editor. |
| `@open-file-line-debug` | `off` | When `on`, the last click's arguments are logged to `/tmp/tmux-open-file-line.last`. |

Example:

```tmux
set -g @open-file-line-editor 'nvim'
set -g @open-file-line-markdown-cmd ''   # open .md in the editor too
set -g @plugin 'jun-jin/tmux-open-file-line'
```

The environment variable `TMUX_OPEN_EDITOR`, if set in the tmux server's
environment, overrides `@open-file-line-editor`.

## How it works

- The clicked word (`#{mouse_word}`) is trimmed of surrounding quotes and
  brackets and parsed as `path`, `path:line`, `path:line:col` or
  `path:start-stop`.
- `~/` and relative paths are resolved against the pane's current directory.
- If the clicked word is not an existing file, every path-looking token on the
  clicked line (`#{mouse_line}`) is tried in turn.
- Clicks inside a pane running the editor itself are ignored, so Alt+Click in
  vim still behaves as before.
- The file is opened with `tmux new-window -a -c <pane dir> "<editor> +<line> -- <file>"`.
  For a range, `-c 'normal! <start>GV<stop>G'` is appended so the lines end up
  selected (vim/nvim).

## Troubleshooting

Enable `@open-file-line-debug` and inspect `/tmp/tmux-open-file-line.last`
after a click that did nothing. It shows the word, directory, line text and
pane command the handler received.
