#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-suggest.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" != *"AI_COMPLETE_RENDER_MODE"* ]] || {
    print -u2 "expected render mode env config to be removed"
    exit 1
}

[[ "$content" == *"_ai_adjust_render_mode_for_space"* ]] || {
    print -u2 "expected built-in space-based fallback logic to remain"
    exit 1
}

print "ok"
