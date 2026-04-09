#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" == *"bindkey '^G'   ai-ask"* ]] || {
    print -u2 "expected Ctrl+G binding in main keymap"
    exit 1
}

[[ "$content" == *"bindkey -M emacs '^G' ai-ask"* ]] || {
    print -u2 "expected Ctrl+G binding in emacs keymap"
    exit 1
}

[[ "$content" == *"bindkey -M viins '^G' ai-ask"* ]] || {
    print -u2 "expected Ctrl+G binding in vi insert keymap"
    exit 1
}

print "ok"
