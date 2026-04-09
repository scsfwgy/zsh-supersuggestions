#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

show_answer_block=${content#*"_ai_show_answer() {"}
show_answer_block=${show_answer_block%%$'\n}'*}

[[ "$show_answer_block" == *"zle -I"* ]] || {
    print -u2 "expected _ai_show_answer to invalidate ZLE display before printing output"
    exit 1
}

print "ok"
