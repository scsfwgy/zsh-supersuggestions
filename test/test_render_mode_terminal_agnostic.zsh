#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" != *"Apple_Terminal|iTerm.app"* ]] || {
    print -u2 "expected space-based fallback to no longer be limited to specific terminals"
    exit 1
}

print "ok"
