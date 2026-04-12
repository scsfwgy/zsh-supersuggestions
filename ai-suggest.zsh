# AI Suggestion Menu — Ctrl+L core module
#
# Provides AI-powered command suggestion list with bordered menu rendering.
# Sourced by ai-complete.zsh — do not source independently.

# ── State ─────────────────────────────────────────────────────
_AI_SUGGESTIONS=()
_AI_INDEX=0
_AI_ACTIVE=0
_AI_ORIGINAL=""
_AI_RIGHT=""
_AI_SCROLL=0
_AI_LIST_LINES=0
_AI_CURSOR_ROW=0

# ── Clamp scroll window ──────────────────────────────────────
_ai_clamp_scroll() {
    (( _AI_INDEX < _AI_SCROLL )) && _AI_SCROLL=$((_AI_INDEX))
    (( _AI_INDEX >= _AI_SCROLL + _AI_MAX_ITEMS )) && _AI_SCROLL=$(( _AI_INDEX - _AI_MAX_ITEMS + 1 ))
    (( _AI_SCROLL < 0 )) && _AI_SCROLL=0
}

# ── Menu line count ───────────────────────────────────────────
_ai_menu_lines() {
    local n=${#_AI_SUGGESTIONS}
    local max=${_AI_MAX_ITEMS}
    (( max > n )) && max=$n
    print $(( max + 2 ))
}

# ── Render mode adjustment ───────────────────────────────────
_ai_adjust_render_mode_for_space() {
    _AI_RENDER_MODE="multiline"

    local lines_available=${LINES:-0}
    local menu_lines=$(_ai_menu_lines)
    local cursor_row=${_AI_CURSOR_ROW:-0}
    local remaining_lines=$(( lines_available - cursor_row ))
    if (( lines_available > 0 && cursor_row > 0 && remaining_lines <= menu_lines )); then
        _AI_RENDER_MODE="inline"
    fi
}

# ── Cursor position helpers ──────────────────────────────────
_ai_parse_cursor_row() {
    local response="$1"
    local payload row column

    [[ "$response" == $'\e['*';'*'R' ]] || return

    payload="${response#$'\e['}"
    row="${payload%%;*}"
    column="${payload#*;}"
    column="${column%R}"

    [[ "$row" == <-> && "$column" == <-> ]] || return
    print -- "$row"
}

_ai_write_cursor_query() {
    local tty_path="$1"
    printf '\e[6n' > "$tty_path"
}

_ai_get_cursor_row() {
    local tty_path="${_AI_TTY_PATH:-/dev/tty}"
    local saved_stty response char row

    saved_stty=$(stty -g < "$tty_path" 2>/dev/null) || {
        print -- ""
        return
    }

    {
        stty -echo -icanon time 1 min 0 < "$tty_path" 2>/dev/null || return
        _ai_write_cursor_query "$tty_path"

        while read -r -k 1 char < "$tty_path" 2>/dev/null; do
            response+="$char"
            [[ "$char" == "R" ]] && break
        done
    } always {
        [[ -n "$saved_stty" ]] && stty "$saved_stty" < "$tty_path" 2>/dev/null
    }

    row=$(_ai_parse_cursor_row "$response")
    print -- "$row"
}

# ── Clear rendered menu ───────────────────────────────────────
_ai_clear_menu() {
    if [[ "$_AI_RENDER_MODE" == "inline" ]]; then
        zle -M ""
        _AI_LIST_LINES=0
        return
    fi

    (( _AI_LIST_LINES > 0 )) || return

    local i
    printf '\e7'
    printf '\e[B\r'
    for (( i = 0; i < _AI_LIST_LINES; i++ )); do
        printf '\r\e[2K'
        (( i + 1 < _AI_LIST_LINES )) && printf '\e[B'
    done
    printf '\e8'
    _AI_LIST_LINES=0
}

# ── Reset menu state ──────────────────────────────────────────
_ai_reset_menu() {
    _AI_ACTIVE=0
    _AI_SUGGESTIONS=()
    _AI_INDEX=0
    _AI_SCROLL=0
    _AI_LIST_LINES=0
    _AI_RIGHT=""
}

# ── Detect whether buffer changed since menu opened ───────────
_ai_buffer_changed() {
    [[ "$LBUFFER" != "$_AI_ORIGINAL" || "$RBUFFER" != "$_AI_RIGHT" ]]
}

# ── Render current suggestion inline ──────────────────────────
_ai_show_inline() {
    local n=${#_AI_SUGGESTIONS}
    local item="${_AI_SUGGESTIONS[$(( _AI_INDEX + 1 ))]}"
    zle -M "AI [$(( _AI_INDEX + 1 ))/$n] $item"
    _AI_LIST_LINES=0
}

# ── Render bordered vertical list ────────────────────────────
_ai_show() {
    (( ${#_AI_SUGGESTIONS} > 0 )) || return

    _AI_CURSOR_ROW=$(_ai_get_cursor_row)
    _ai_adjust_render_mode_for_space
    if [[ "$_AI_RENDER_MODE" == "inline" ]]; then
        _ai_show_inline
        return
    fi

    _ai_clamp_scroll

    _ai_clear_menu

    # Let ZLE refresh the command line AFTER old menu is cleared
    zle redisplay

    # DEC save cursor (separate slot from CSI s/u, avoids ZLE conflicts)
    printf '\e7'
    # Move down one line, go to col 0, clear to end of screen
    printf '\e[B\r\e[J'

    local n=${#_AI_SUGGESTIONS}
    local max=${_AI_MAX_ITEMS}
    (( max > n )) && max=$n
    local s=$_AI_SCROLL
    local e=$(( s + max ))
    (( e > n )) && e=$n

    # Max item width
    local w=15 idx ilen
    for (( idx = s; idx < e; idx++ )); do
        ilen=${#_AI_SUGGESTIONS[$(( idx + 1 ))]}
        (( ilen > w )) && w=$ilen
    done
    (( w > 50 )) && w=50

    local inner=$(( w + 5 ))
    local dashes="${(l:$(( inner ))::─:)}"

    # Top border
    local header=" AI"
    (( s > 0 )) && header+=" ▲"
    (( e < n )) && header+=" ▼"
    header+=" "
    local left_dashes="${(l:$(( inner - ${#header} ))::─:)}"
    printf '┌%s%s┐\n' "$header" "$left_dashes"

    # Items
    local item pad
    for (( idx = s; idx < e; idx++ )); do
        item="${_AI_SUGGESTIONS[$(( idx + 1 ))]}"
        pad="${(l:$(( w - ${#item} )):: :)}"
        if (( idx == _AI_INDEX )); then
            printf '│ ❯  %s%s │\n' "$item" "$pad"
        else
            printf '│    %s%s │\n' "$item" "$pad"
        fi
    done

    # Bottom border
    printf '└%s┘' "$dashes"

    _AI_LIST_LINES=$(( e - s + 2 ))  # items + top + bottom

    # DEC restore cursor to command line
    printf '\e8'
}

# ── Ctrl+L: fetch / refresh suggestions ───────────────────
_ai_trigger() {
    local input="${LBUFFER}"
    local config_message

    _ai_history_reset

    [[ -z "${input// /}" ]] && { zle expand-or-complete; return }

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

    _AI_ORIGINAL="$input"
    _AI_RIGHT="$RBUFFER"
    _AI_INDEX=0
    _AI_SCROLL=0

    _ai_run_with_spinner ai-command-request.sh list "$input"
    local raw="$_AI_LAST_OUTPUT"

    [[ -z "$raw" ]] && { _ai_reset_menu; zle expand-or-complete; return }

    _AI_SUGGESTIONS=("${(@f)raw}")
    (( ${#_AI_SUGGESTIONS} > 0 )) || { _ai_reset_menu; zle expand-or-complete; return }

    _AI_ACTIVE=1
    _ai_show
}

# ── Suggestion menu navigation ────────────────────────────────
_ai_suggest_up() {
    (( ${#_AI_SUGGESTIONS} > 0 )) || return
    _AI_INDEX=$(( (_AI_INDEX - 1 + ${#_AI_SUGGESTIONS}) % ${#_AI_SUGGESTIONS} ))
    _ai_show
}

_ai_suggest_down() {
    (( ${#_AI_SUGGESTIONS} > 0 )) || return
    _AI_INDEX=$(( (_AI_INDEX + 1) % ${#_AI_SUGGESTIONS} ))
    _ai_show
}

# ── Suggestion menu accept/cancel ─────────────────────────────
_ai_suggest_accept() {
    (( ${#_AI_SUGGESTIONS} > 0 )) || return
    _ai_clear_menu
    _ai_history_reset
    LBUFFER="${_AI_SUGGESTIONS[$(( _AI_INDEX + 1 ))]}"
    RBUFFER="$_AI_RIGHT"
    _ai_reset_menu
    zle redisplay
}

_ai_suggest_cancel() {
    _ai_clear_menu
    _ai_history_reset
    LBUFFER="$_AI_ORIGINAL"
    RBUFFER="$_AI_RIGHT"
    _ai_reset_menu
    zle redisplay
}
