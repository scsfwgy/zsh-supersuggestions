#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
SUGGEST_FILE="$PROJECT_DIR/ai-suggest.zsh"
ENTRY_FILE="$PROJECT_DIR/ai-complete.zsh"
suggest_content=$(<"$SUGGEST_FILE")
entry_content=$(<"$ENTRY_FILE")

[[ "$suggest_content" == *"_ai_trigger()"* ]] || {
    print -u2 "expected trigger function to be renamed to _ai_trigger"
    exit 1
}

[[ "$entry_content" == *"zle -N ai-trigger _ai_trigger"* ]] || {
    print -u2 "expected trigger widget registration to use ai-trigger/_ai_trigger"
    exit 1
}

[[ "$entry_content" == *'bindkey "$_AI_TRIGGER_BINDKEY" ai-trigger'* ]] || {
    print -u2 "expected trigger binding to target ai-trigger"
    exit 1
}

[[ "$suggest_content" != *"_ai_tab()"* ]] || {
    print -u2 "expected legacy _ai_tab name to be removed"
    exit 1
}

print "ok"
