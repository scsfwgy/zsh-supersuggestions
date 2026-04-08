#!/bin/zsh
set -euo pipefail

TEST_DIR=${0:A:h}
PROJECT_DIR=${TEST_DIR:h}

bindkey() { :; }
zle() { :; }

source "$PROJECT_DIR/ai-complete.zsh" >/dev/null

AI_COMPLETE_RENDER_MODE=auto
TERM_PROGRAM=Apple_Terminal
LINES=10
_ai_setup_render_mode

_AI_SUGGESTIONS=('ls -la' 'ls -lh' 'ls -laR' 'ls -lS' 'ls -lt')
_AI_SCROLL=0
_AI_INDEX=0
_AI_RENDER_MODE=multiline
_AI_LAST_LINES=8

_ai_adjust_render_mode_for_space
[[ "$_AI_RENDER_MODE" == "inline" ]] || {
    print -u2 "expected auto mode to fall back to inline when remaining lines are insufficient"
    exit 1
}

_AI_RENDER_MODE=multiline
_AI_LAST_LINES=2
_ai_adjust_render_mode_for_space
[[ "$_AI_RENDER_MODE" == "multiline" ]] || {
    print -u2 "expected auto mode to keep multiline when enough lines remain"
    exit 1
}

AI_COMPLETE_RENDER_MODE=multiline
_AI_RENDER_MODE=multiline
_AI_LAST_LINES=8
_ai_adjust_render_mode_for_space
[[ "$_AI_RENDER_MODE" == "multiline" ]] || {
    print -u2 "expected explicit multiline mode to bypass space-based fallback"
    exit 1
}

print "ok"
