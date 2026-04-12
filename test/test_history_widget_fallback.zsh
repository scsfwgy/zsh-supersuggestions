#!/bin/zsh
set -euo pipefail

TEST_DIR=${0:A:h}
PROJECT_DIR=${TEST_DIR:h}

bindkey_log=()
bindkey() {
    bindkey_log+=("$*")
}
zle_log=()
zle() {
    zle_log+=("$1")
}
_zsh_autosuggest_start() { :; }

source "$PROJECT_DIR/ai-complete.zsh" >/dev/null
_ai_get_cursor_row() {
    print -- "1"
}
_ai_show() {
    :
}

[[ " ${bindkey_log[*]} " == *" -M emacs ^U ai-history-prev "* ]] || {
    print -u2 "expected history prev binding in emacs keymap"
    exit 1
}
[[ " ${bindkey_log[*]} " == *" -M viins ^N ai-history-next "* ]] || {
    print -u2 "expected history next binding in viins keymap"
    exit 1
}

zle_log=()
_AI_ACTIVE=0
LBUFFER=''
RBUFFER=''
_ai_history_prev
[[ " ${zle_log[*]} " == *" kill-line "* ]] || {
    print -u2 "expected previous history fallback to call kill-line"
    exit 1
}

zle_log=()
_ai_history_next
[[ " ${zle_log[*]} " == *" down-line-or-history "* ]] || {
    print -u2 "expected next history fallback to call down-line-or-history"
    exit 1
}

zle_log=()
_AI_ACTIVE=1
_AI_SUGGESTIONS=('ls -la' 'ls -lh')
_AI_INDEX=0
_ai_history_prev
[[ $_AI_INDEX -eq 1 ]] || {
    print -u2 "expected previous history widget to delegate to AI up navigation when AI menu is active"
    exit 1
}

zle_log=()
_ai_history_next
[[ $_AI_INDEX -eq 0 ]] || {
    print -u2 "expected next history widget to delegate to AI down navigation when AI menu is active"
    exit 1
}

print "ok"
