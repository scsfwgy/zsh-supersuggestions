# Ctrl+G Terminal Assistant Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `Ctrl+G` shortcut that sends the current command line text to the LLM as a simple question and renders the answer below the prompt without replacing the current buffer.

**Architecture:** Reuse the existing `ai-suggest` script as the single API client, adding a second mode for plain-text assistant answers. Extend `ai-complete.zsh` with a dedicated ask widget that mirrors the current background/spinner pattern, clears any active menu first, and prints a multiline response below the command line while restoring the cursor to the editing position.

**Tech Stack:** zsh ZLE widgets, Bash, curl, jq, existing shell-based regression tests

---

## File Structure

- Modify `ai-suggest`
  - Add a mode switch so the same script can return either cleaned command suggestions or a plain assistant answer.
  - Keep the current suggestion-cleaning pipeline unchanged for suggestion mode.
- Modify `ai-complete.zsh`
  - Add a `Ctrl+G` widget and helper for printing assistant output below the command line.
  - Reuse the existing spinner/background-job pattern.
  - Keep AI menu state isolated from ask-output rendering.
- Create `test/test_ai_ask_mode.zsh`
  - Verify `ai-suggest --ask` returns plain assistant text instead of running command-cleanup logic.
- Create `test/test_ctrl_g_binding.zsh`
  - Verify the new widget is registered, `Ctrl+G` is bound, and startup text mentions the shortcut.
- Modify `test.sh`
  - Run the two new regression tests.

### Task 1: Add a failing regression test for ask mode

**Files:**
- Create: `test/test_ai_ask_mode.zsh`
- Modify: none
- Test: `test/test_ai_ask_mode.zsh`

- [ ] **Step 1: Write the failing test**

```zsh
#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/curl" <<'EOF'
#!/bin/sh
cat <<'JSON'
{
  "choices": [
    {
      "message": {
        "content": "Here is the answer.\n- keep this bullet\n\nUse grep -R foo ."
      }
    }
  ]
}
JSON
EOF
chmod +x "$TMP_DIR/curl"

output=$(PATH="$TMP_DIR:$PATH" AI_COMPLETE_API_KEY="test-key" bash "$PROJECT_DIR/ai-suggest" --ask "why did grep fail")
expected=$'Here is the answer.\n- keep this bullet\n\nUse grep -R foo .'

[[ "$output" == "$expected" ]] || {
    print -u2 "expected plain assistant response:"
    print -u2 "$expected"
    print -u2 "got:"
    print -u2 "$output"
    exit 1
}

print "ok"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `zsh test/test_ai_ask_mode.zsh`
Expected: FAIL because `ai-suggest` does not yet support `--ask` and/or still applies suggestion cleanup semantics.

- [ ] **Step 3: Write minimal implementation**

Update `ai-suggest` so it accepts `--ask` before the user input, sets `MODE="ask"`, uses a dedicated prompt, and bypasses the suggestion cleanup pipeline for ask responses:

```bash
MODE="suggest"
if [[ "${1:-}" == "--ask" ]]; then
    MODE="ask"
    shift
fi

INPUT="$*"
```

```bash
if [[ "$MODE" == "ask" ]]; then
    PROMPT="You are a terminal assistant.
The user entered: \"$INPUT\"

Rules:
- Reply in concise plain text suitable for reading in a terminal
- The input may be a command, an error message, or a natural-language question
- Do not use markdown code fences
- Keep helpful structure when useful
- Do not number the response unless needed

Now reply to: \"$INPUT\""
else
    PROMPT="...existing suggestion prompt..."
fi
```

```bash
content=$(printf '%s' "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

if [[ "$MODE" == "ask" ]]; then
    printf '%s\n' "$content"
    exit 0
fi

printf '%s' "$content" | awk '...existing cleanup program...'
```

- [ ] **Step 4: Run test to verify it passes**

Run: `zsh test/test_ai_ask_mode.zsh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/test_ai_ask_mode.zsh ai-suggest
git commit -m "feat: add terminal ask mode"
```

### Task 2: Add a failing regression test for the Ctrl+G widget and binding

**Files:**
- Create: `test/test_ctrl_g_binding.zsh`
- Modify: none
- Test: `test/test_ctrl_g_binding.zsh`

- [ ] **Step 1: Write the failing test**

```zsh
#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
content=$(<"$PLUGIN_FILE")

[[ "$content" == *"zle -N ai-ask _ai_ask"* ]] || {
    print -u2 "expected ai-ask widget to be registered"
    exit 1
}

[[ "$content" == *"bindkey '^G'   ai-ask"* ]] || {
    print -u2 "expected Ctrl+G to be bound to ai-ask"
    exit 1
}

[[ "$content" == *"Ctrl+G → ask AI"* ]] || {
    print -u2 "expected startup text to mention Ctrl+G ask shortcut"
    exit 1
}

print "ok"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `zsh test/test_ctrl_g_binding.zsh`
Expected: FAIL because the widget, key binding, and startup text do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Add a dedicated ask widget in `ai-complete.zsh` that:

- reads `LBUFFER` as the prompt text
- returns immediately if the input is blank
- clears/reset the menu if `_AI_ACTIVE` is set
- runs `ai-suggest --ask "$input"` in the background via `{ ... } &!`
- shows the existing inline spinner via `POSTDISPLAY`
- prints the answer below the prompt using DEC save/restore cursor handling
- restores `LBUFFER`, `RBUFFER`, and normal editing state

Use this shape:

```zsh
_ai_show_answer() {
    local text="$1"
    local line

    [[ -n "$text" ]] || return

    _ai_clear_menu
    zle redisplay
    printf '\e7'
    printf '\e[B\r'
    while IFS= read -r line; do
        printf '\r\e[2K%s\n' "$line"
    done <<< "$text"
    printf '\e8'
}
```

```zsh
_ai_ask() {
    local input="${LBUFFER}"
    [[ -z "${input// /}" ]] && return

    if (( _AI_ACTIVE )); then
        _ai_clear_menu
        _ai_reset_menu
    fi

    local tmpf; tmpf=$(mktemp)
    { ai-suggest --ask "$input" > "$tmpf" } 2>/dev/null &!
    local bg_pid=$!

    local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠧' '⠇' '⠏')
    local si=0
    while kill -0 "$bg_pid" 2>/dev/null; do
        POSTDISPLAY=" ${spin[$(( si % 9 + 1 ))]}"
        zle redisplay
        si=$(( si + 1 ))
        sleep 0.1
    done

    local answer; answer=$(cat "$tmpf" 2>/dev/null)
    rm -f "$tmpf"
    POSTDISPLAY=""
    zle redisplay

    [[ -n "$answer" ]] && _ai_show_answer "$answer"
}
```

Register and bind it:

```zsh
zle -N ai-ask    _ai_ask
bindkey '^G'   ai-ask
```

Update the startup text:

```zsh
echo "AI command completion loaded. Shift+Tab → suggest, Ctrl+G → ask AI, ↑↓ → navigate, Enter → accept."
```

- [ ] **Step 4: Run test to verify it passes**

Run: `zsh test/test_ctrl_g_binding.zsh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/test_ctrl_g_binding.zsh ai-complete.zsh
git commit -m "feat: add ctrl-g ask widget"
```

### Task 3: Wire the new tests into the test runner

**Files:**
- Modify: `test.sh:14-25`
- Test: `test.sh`

- [ ] **Step 1: Write the failing test update**

Insert the new test invocations near related coverage in `test.sh`:

```zsh
run_test "ai-suggest cleanup regression" "$TEST_DIR/test_ai_suggest_cleanup.zsh"
run_test "ai ask mode regression" "$TEST_DIR/test_ai_ask_mode.zsh"
run_test "shift+tab binding regression" "$TEST_DIR/test_shift_tab_binding.zsh"
run_test "ctrl+g binding regression" "$TEST_DIR/test_ctrl_g_binding.zsh"
```

- [ ] **Step 2: Run test runner to verify it fails**

Run: `zsh test.sh`
Expected: FAIL because the new test files and implementation are not both present yet.

- [ ] **Step 3: Write minimal implementation**

Ensure `test.sh` contains the new lines exactly once and preserves the existing order for all previous regression tests.

- [ ] **Step 4: Run test runner to verify it passes**

Run: `zsh test.sh`
Expected: every test prints `ok`, including the new ask-mode and Ctrl+G regressions.

- [ ] **Step 5: Commit**

```bash
git add test.sh test/test_ai_ask_mode.zsh test/test_ctrl_g_binding.zsh ai-suggest ai-complete.zsh
git commit -m "test: cover ctrl-g terminal assistant flow"
```

### Task 4: Manual terminal verification of the interaction

**Files:**
- Modify: none
- Test: manual shell session using `ai-complete.zsh`

- [ ] **Step 1: Start an interactive zsh with the plugin loaded**

Run:

```bash
zsh -ic 'source ./ai-complete.zsh'
```

Expected: startup banner mentions `Ctrl+G → ask AI`

- [ ] **Step 2: Verify the ask flow manually**

In the interactive shell, type a sample prompt such as:

```text
git rebase 报错是什么意思
```

Then press `Ctrl+G`.

Expected:
- a spinner appears inline after the current input
- the answer renders below the command line
- the original input remains on the prompt for further editing
- no selection menu is activated

- [ ] **Step 3: Verify suggestion flow still works**

In the same shell, type:

```text
gti
```

Then press `Shift+Tab`.

Expected:
- the existing suggestion menu appears
- up/down navigation still works
- Enter still inserts the selected command

- [ ] **Step 4: Verify ask-after-menu behavior**

Open the suggestion menu first, then press `Ctrl+G` on a non-empty input.

Expected:
- the old menu is cleared cleanly
- the answer prints below the prompt
- no stale menu lines remain on screen

- [ ] **Step 5: Commit**

```bash
git add ai-complete.zsh ai-suggest test.sh test/test_ai_ask_mode.zsh test/test_ctrl_g_binding.zsh
git commit -m "feat: add ctrl-g terminal assistant output"
```

## Self-Review

- **Spec coverage:** The plan covers the approved design: reuse `ai-suggest`, add a dedicated ask prompt, bind `Ctrl+G`, render output below the prompt, preserve existing Shift+Tab behavior, and verify both automated and manual behavior.
- **Placeholder scan:** No `TODO`/`TBD` placeholders remain; each task includes exact files, code snippets, commands, and expected outcomes.
- **Type consistency:** Function and widget names are consistent across tasks: `ai-suggest --ask`, `_ai_ask`, `_ai_show_answer`, and `ai-ask`.
