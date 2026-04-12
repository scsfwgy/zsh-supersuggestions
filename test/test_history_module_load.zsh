#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
MODULE_FILE="$PROJECT_DIR/zsh-autosuggestions-enhance.sh"
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"

[[ -f "$MODULE_FILE" ]] || {
    print -u2 "expected history enhancement module file to exist"
    exit 1
}

module_content=$(<"$MODULE_FILE")
plugin_content=$(<"$PLUGIN_FILE")

[[ "$module_content" == *"_ai_hist_collect_candidates()"* ]] || {
    print -u2 "expected enhancement module to collect history candidates"
    exit 1
}

[[ "$module_content" == *"_ai_history_prev_handler()"* ]] || {
    print -u2 "expected enhancement module to override previous-history handler"
    exit 1
}

[[ "$module_content" == *"_ai_history_next_handler()"* ]] || {
    print -u2 "expected enhancement module to override next-history handler"
    exit 1
}

[[ "$plugin_content" == *"_ai_load_history_enhancement()"* ]] || {
    print -u2 "expected ai-complete entrypoint to load enhancement module"
    exit 1
}

[[ "$plugin_content" == *'source "$enhance_script"'* ]] || {
    print -u2 "expected ai-complete entrypoint to source enhancement module"
    exit 1
}

print "ok"
