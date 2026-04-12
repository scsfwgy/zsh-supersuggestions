#!/bin/zsh
set -euo pipefail

TEST_DIR=${0:A:h}
PROJECT_DIR=${TEST_DIR:h}

bindkey() { :; }
last_zle_call=''
zle() {
    last_zle_call="$1"
}
_zsh_autosuggest_start() { :; }

source "$PROJECT_DIR/ai-complete.zsh" >/dev/null
fc() {
    case "$*" in
        '-rln 1')
            print -- $'git checkout feature/test\ngit checkout dev'
            ;;
        *)
            return 1
            ;;
    esac
}
HISTFILE=''

LBUFFER='git checkout '
RBUFFER=''
POSTDISPLAY=''
_ai_history_next
[[ "$POSTDISPLAY" == 'feature/test' ]] || {
    print -u2 "expected history overlay to show current candidate suffix"
    print -u2 "$POSTDISPLAY"
    exit 1
}
_ai_enter
[[ "$LBUFFER" == 'git checkout feature/test' ]] || {
    print -u2 "expected enter to accept current history candidate"
    exit 1
}
[[ "$POSTDISPLAY" == '' ]] || {
    print -u2 "expected enter to clear history overlay"
    exit 1
}
[[ $_AI_HIST_ACTIVE -eq 0 ]] || {
    print -u2 "expected enter to reset history active state"
    exit 1
}

LBUFFER='git checkout '
POSTDISPLAY=''
_ai_history_next
_ai_cancel
[[ "$POSTDISPLAY" == '' ]] || {
    print -u2 "expected cancel to clear history overlay"
    exit 1
}
[[ $_AI_HIST_ACTIVE -eq 0 ]] || {
    print -u2 "expected cancel to reset history active state"
    exit 1
}

print "ok"
