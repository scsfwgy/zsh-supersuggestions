#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" != *"AI_COMPLETE_RENDER_MODE"* ]] || {
    print -u2 "expected render mode env config to be removed"
    exit 1
}

[[ "$content" == *"Apple_Terminal|iTerm.app"* ]] || {
    print -u2 "expected built-in native terminal fallback detection to remain"
    exit 1
}

print "ok"
