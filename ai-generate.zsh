# AI Generate — Ctrl+G core module
#
# Provides AI-powered command generation with answer display.
# Sourced by ai-complete.zsh — do not source independently.

# ── Show AI answer below command line ─────────────────────────
_ai_show_answer() {
    local text="$1"
    [[ -n "$text" ]] || return

    _ai_clear_menu
    zle redisplay

    # Print answer below command line (question text stays above as history)
    printf '\e[B\r\e[J'
    printf '%s\n' "$text"

    # New empty prompt at current cursor position (after the answer)
    # Do NOT use zle -I here — it causes full screen redraw on some systems
    LBUFFER=""
    RBUFFER=""
    zle reset-prompt
}

# ── Ctrl+G: ask AI and render answer (g = generate) ──────────
_ai_ask() {
    local input="${LBUFFER}"
    local config_message

    _ai_history_reset
    [[ -z "${input// /}" ]] && return

    if config_message=$(_ai_missing_config_message); then
        _ai_clear_menu
        _ai_reset_menu
        zle -M "$config_message"
        return
    fi

    if (( _AI_ACTIVE )); then
        _ai_clear_menu
        _ai_reset_menu
    fi

    _ai_run_with_spinner ai-command-request.sh generate "$input"
    local answer="$_AI_LAST_OUTPUT"

    _ai_show_answer "${answer:-no response}"
}
