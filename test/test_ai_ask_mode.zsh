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

cat > "$TMP_DIR/curl" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$TMP_DIR/curl"

empty_output=$(PATH="$TMP_DIR:$PATH" AI_COMPLETE_API_KEY="test-key" bash "$PROJECT_DIR/ai-suggest" --ask "bash和zsh的区别？")
empty_expected='AI ask failed: empty response from API'

[[ "$empty_output" == "$empty_expected" ]] || {
    print -u2 "expected empty-response warning:"
    print -u2 "$empty_expected"
    print -u2 "got:"
    print -u2 "$empty_output"
    exit 1
}

print "ok"
