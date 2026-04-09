#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" == *"zle -N ai-ask _ai_ask"* ]] || {
    print -u2 "expected ai-ask widget to be registered"
    exit 1
}

[[ "$content" == *"bindkey '^G'   ai-ask"* ]] || {
    print -u2 "expected Ctrl+G to be bound to ai-ask"
    exit 1
}

[[ "$content" == *"Ctrl+G → ask AI"* ]] || {
    print -u2 "expected startup text to mention Ctrl+G ask shortcut"
    exit 1
}

print "ok"
