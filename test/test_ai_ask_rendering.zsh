#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

show_answer_block=${content#*"_ai_show_answer() {"}
show_answer_block=${show_answer_block%%$'\n}'*}

[[ "$show_answer_block" == *"[AI ERROR]"* ]] || {
    print -u2 "expected ask errors to be rendered with a visible [AI ERROR] marker"
    exit 1
}

restore_marker="printf '\\e8'"
[[ "$show_answer_block" == *"$restore_marker"* ]] || {
    print -u2 "expected _ai_show_answer to restore the cursor with DEC restore"
    exit 1
}

post_restore_block=${show_answer_block#*"$restore_marker"}

[[ "$post_restore_block" == *"zle redisplay"* ]] || {
    print -u2 "expected _ai_show_answer to call zle redisplay after restoring cursor"
    exit 1
}

print "ok"
