#!/bin/zsh
set -euo pipefail

TEST_DIR=${0:A:h}
PROJECT_DIR=${TEST_DIR:h}

bindkey() { :; }
redisplay_count=0
zle() {
    case "$1" in
        redisplay)
            redisplay_count=$(( redisplay_count + 1 ))
            ;;
        -N|-M|expand-or-complete|down-line-or-history|up-line-or-history|accept-line|send-break|kill-line|reset-prompt|-R)
            ;;
    esac
}
_zsh_autosuggest_start() { :; }

source "$PROJECT_DIR/ai-complete.zsh" >/dev/null
fc() {
    case "$*" in
        '-rln 1')
            print -- $'git checkout feature/test\ngit checkout dev\ngit checkout main\ngit checkout dev'
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
[[ $_AI_HIST_ACTIVE -eq 1 ]] || {
    print -u2 "expected history next to activate history overlay"
    exit 1
}
[[ ${#_AI_HIST_SUGGESTIONS[@]} -eq 3 ]] || {
    print -u2 "expected history candidates to be deduplicated"
    exit 1
}
[[ "$POSTDISPLAY" == 'feature/test' ]] || {
    print -u2 "expected history overlay to show suffix for first candidate"
    print -u2 "$POSTDISPLAY"
    exit 1
}

LBUFFER=' git checkout '
POSTDISPLAY=''
_ai_history_reset
_AI_HIST_SUGGESTIONS=(' git checkout main')
_AI_HIST_INDEX=0
_ai_hist_show_inline
[[ "$POSTDISPLAY" == 'main' ]] || {
    print -u2 "expected suffix logic to work when prefix starts with a space"
    print -u2 "$POSTDISPLAY"
    exit 1
}

LBUFFER='git checkout '
POSTDISPLAY=''
_ai_history_next
[[ "$POSTDISPLAY" == 'dev' ]] || {
    print -u2 "expected history next to cycle forward"
    print -u2 "$POSTDISPLAY"
    exit 1
}

_ai_history_prev
[[ "$POSTDISPLAY" == 'feature/test' ]] || {
    print -u2 "expected history prev to cycle backward"
    print -u2 "$POSTDISPLAY"
    exit 1
}

LBUFFER='git checkout d'
POSTDISPLAY=''
fc() {
    case "$*" in
        '-rln 1')
            print -- 'git checkout dev'
            ;;
        *)
            return 1
            ;;
    esac
}
_ai_history_next
[[ ${#_AI_HIST_SUGGESTIONS[@]} -eq 1 ]] || {
    print -u2 "expected history candidates to refresh when prefix changes"
    exit 1
}
[[ "$POSTDISPLAY" == 'ev' ]] || {
    print -u2 "expected refreshed overlay to match new prefix suffix"
    print -u2 "$POSTDISPLAY"
    exit 1
}

print "ok"
