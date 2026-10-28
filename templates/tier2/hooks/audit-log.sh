#!/bin/bash
# audit-log.sh - PostToolUse hook. Appends one line per tool call to
# ~/cogent/audit/YYYY-MM-DD.log: time, tool name, short session id, short detail.
# It never logs tool output, and never blocks anything (always exits 0).
umask 077
COGENT_DIR="${COGENT_HOME:-$HOME/cogent}"
AUDIT_DIR="$COGENT_DIR/audit"
mkdir -p "$AUDIT_DIR" 2>/dev/null
chmod 700 "$AUDIT_DIR" 2>/dev/null
INPUT="$(cat)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOGFILE="$AUDIT_DIR/$(date +%Y-%m-%d).log"
LINE=""
if command -v jq >/dev/null 2>&1; then
  LINE="$(printf '%s' "$INPUT" | jq -r '[(.tool_name // "?"), ((.session_id // "?") | tostring | .[0:8]), ((.tool_input.command // .tool_input.file_path // .tool_input.notebook_path // .tool_input.path // .tool_input.pattern // .tool_input.url // "") | tostring | gsub("[\\r\\n\\t]+"; " ") | .[0:160])] | @tsv' 2>/dev/null)"
fi
if [ -z "$LINE" ]; then
  LINE="$(printf '%s' "$INPUT" | python3 -c '
import json, re, sys
try:
    d = json.loads(sys.stdin.read())
    ti = d.get("tool_input") or {}
    detail = ""
    for k in ("command", "file_path", "notebook_path", "path", "pattern", "url"):
        if ti.get(k):
            detail = str(ti[k])
            break
    detail = re.sub(r"\s+", " ", detail)[:160]
    print("\t".join([str(d.get("tool_name", "?")), str(d.get("session_id", "?"))[:8], detail]))
except Exception:
    print("?\t?\t(could not read hook input)")
' 2>/dev/null)"
fi
[ -z "$LINE" ] && LINE="?	?	(could not read hook input)"
# Blank obvious keys and tokens before writing.
LINE="$(printf '%s' "$LINE" | sed -E 's/(([Bb]earer|[Tt]oken|[Kk]ey|[Ss]ecret|[Pp]assword|[Pp]wd)[=: ]+)[^ \t]+/\1[redacted]/g; s/sk-[A-Za-z0-9_-]{10,}/[redacted]/g; s/AKIA[0-9A-Z]{12,}/[redacted]/g; s/gh[pousr]_[A-Za-z0-9]{20,}/[redacted]/g')"
printf '%s\t%s\n' "$NOW" "$LINE" >> "$LOGFILE" 2>/dev/null
exit 0
