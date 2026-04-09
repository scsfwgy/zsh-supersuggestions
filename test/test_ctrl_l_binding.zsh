#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" == *"bindkey '^L'"*ai-trigger* ]] || {
    print -u2 "expected Ctrl+L to be bound to ai-trigger"
    exit 1
}

[[ "$content" != *"bindkey '^S'  "* ]] || {
    print -u2 "expected old Ctrl+S binding to be removed"
    exit 1
}

[[ "$content" == *"Ctrl+L → list suggestions"* ]] || {
    print -u2 "expected startup text to mention Ctrl+L list shortcut"
    exit 1
}

print "ok"
