#!/bin/zsh
set -euo pipefail

PROJECT_DIR=${0:A:h:h}
PLUGIN_FILE="$PROJECT_DIR/ai-complete.zsh"
TMP_ROOT=$(mktemp -d)
VENDOR_DIR="$PROJECT_DIR/vendor/zsh-autosuggestions"
trap 'rm -rf "$TMP_ROOT" "$VENDOR_DIR"' EXIT

already_loaded_output=$(env -i PATH="$PATH" HOME="$TMP_ROOT/home1" zsh -c '
    mkdir -p "$HOME"
    _zsh_autosuggest_start() { :; }
    source "'$PLUGIN_FILE'"
' 2>&1)
[[ "$already_loaded_output" == *"AI command completion loaded."* ]] || {
    print -u2 "expected plugin to load when official autosuggestions is already loaded"
    print -u2 "$already_loaded_output"
    exit 1
}

auto_source_output=$(env -i PATH="$PATH" HOME="$TMP_ROOT/home2" zsh -c '
    mkdir -p "'$VENDOR_DIR'"
    cat > "'$VENDOR_DIR'/zsh-autosuggestions.zsh" <<'"'"'EOF'"'"'
_zsh_autosuggest_start() { :; }
EOF
    source "'$PLUGIN_FILE'"
' 2>&1)
[[ "$auto_source_output" == *"AI command completion loaded."* ]] || {
    print -u2 "expected plugin to auto-source vendored zsh-autosuggestions"
    print -u2 "$auto_source_output"
    exit 1
}

rm -rf "$VENDOR_DIR"

manual_install_output=$(env -i PATH="/usr/bin:/bin" HOME="$TMP_ROOT/home3" HOMEBREW_PREFIX="$TMP_ROOT/no-brew" zsh -c '
    mkdir -p "$HOME"
    exec </dev/null
    source "'$PLUGIN_FILE'"
' 2>&1 >/dev/null || true)
[[ "$manual_install_output" == *"TerminalTab requires zsh-users/zsh-autosuggestions."* ]] || {
    print -u2 "expected missing dependency guidance header"
    print -u2 "$manual_install_output"
    exit 1
}
[[ "$manual_install_output" == *"[1] Auto-download now"* || "$manual_install_output" == *"Choose one of the following:"* ]] || {
    print -u2 "expected missing dependency guidance to mention install choices"
    print -u2 "$manual_install_output"
    exit 1
}
[[ "$manual_install_output" == *"brew install zsh-autosuggestions"* ]] || {
    print -u2 "expected manual install command in guidance"
    print -u2 "$manual_install_output"
    exit 1
}
[[ "$manual_install_output" == *"vendor/zsh-autosuggestions"* ]] || {
    print -u2 "expected vendor install path in guidance"
    print -u2 "$manual_install_output"
    exit 1
}

print "ok"
