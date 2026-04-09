#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" == *"bindkey '^X^A' ai-ask"* ]] || {
    print -u2 "expected Ctrl+X Ctrl+A to be bound to ai-ask"
    exit 1
}

[[ "$content" == *"bindkey -M emacs '^X^A' ai-ask"* ]] || {
    print -u2 "expected Ctrl+X Ctrl+A binding in emacs keymap"
    exit 1
}

[[ "$content" == *"bindkey -M viins '^X^A' ai-ask"* ]] || {
    print -u2 "expected Ctrl+X Ctrl+A binding in vi insert keymap"
    exit 1
}

[[ "$content" == *"Ctrl+X Ctrl+A → ask AI"* ]] || {
    print -u2 "expected startup text to mention Ctrl+X Ctrl+A ask shortcut"
    exit 1
}

print "ok"
