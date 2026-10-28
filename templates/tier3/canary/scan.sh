#!/bin/bash
# scan.sh - look for canary strings where they should never appear.
# Exit 0: clean. Exit 1: a canary was found. Exit 2: the scan itself is not valid
# (empty or missing list). An empty list must FAIL, never pass: a scan with nothing
# to look for proves nothing.
COGENT="${COGENT_HOME:-$HOME/cogent}"
umask 077
NEEDLES="$COGENT/canary/needles.txt"

if [ ! -s "$NEEDLES" ]; then echo "SCAN INVALID: $NEEDLES missing or empty" >&2; exit 2; fi
n=$(grep -c . "$NEEDLES")
if [ "$n" -lt 3 ]; then echo "SCAN INVALID: only $n canaries listed, expected at least 3" >&2; exit 2; fi
if awk 'length($0) < 20 { bad=1 } END { exit !bad }' "$NEEDLES"; then
  echo "SCAN INVALID: a canary is shorter than 20 characters (too likely to match by accident)" >&2; exit 2
fi

# This script ignores ~/cogent/STOP on purpose: it only reads, and it is most useful during an incident.
# Places a canary must never be. The canary folder and the decoy are excluded on purpose.
TARGETS=("$HOME/.claude/projects" "$HOME/.claude/history.jsonl" \
         "$COGENT/audit" "$COGENT/outbox" "$COGENT/brain" "$COGENT/mailbox" "$COGENT/logs" "$COGENT/lanes" \
         "$COGENT/notes" "$COGENT/backups" "$COGENT/jobs-workdir" "$COGENT/BUILD-LOG.md" "$HOME/.claude/file-history")
existing=()
for t in "${TARGETS[@]}"; do [ -e "$t" ] && existing+=("$t"); done
if [ ${#existing[@]} -eq 0 ]; then echo "SCAN INVALID: none of the places to scan exist" >&2; exit 2; fi

# -l prints file names only, so the scan output never contains the canary itself.
hits=$(grep -rlF -f "$NEEDLES" "${existing[@]}" 2>/dev/null)
if [ -n "$hits" ]; then
  echo "CANARY FOUND in:" >&2
  echo "$hits" >&2
  [ -x "$COGENT/bin/notify.sh" ] && "$COGENT/bin/notify.sh" "Lane canary-scan needs you: canary found" >/dev/null 2>&1
  exit 1
fi
echo "scan clean: $n canaries checked in ${#existing[@]} places"
exit 0
