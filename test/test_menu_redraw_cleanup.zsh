#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-suggest.zsh"
content=$(<"$PLUGIN_FILE")

show_block=${content#*"_ai_show() {"}
show_block=${show_block%%$'\n}'*}

clear_pos=${show_block[(i)_ai_clear_menu]}
redisplay_pos=${show_block[(i)zle redisplay]}

(( clear_pos <= ${#show_block} )) || {
    print -u2 "expected _ai_show to call _ai_clear_menu"
    exit 1
}

(( redisplay_pos <= ${#show_block} )) || {
    print -u2 "expected _ai_show to call zle redisplay"
    exit 1
}

(( clear_pos < redisplay_pos )) || {
    print -u2 "expected _ai_show to clear old menu before zle redisplay"
    exit 1
}

print "ok"
