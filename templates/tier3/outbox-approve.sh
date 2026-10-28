#!/bin/bash
# outbox-approve.sh - YOU approve one held draft. Run it in your own Terminal window.
# Usage: outbox-approve.sh <draft-file-name-in-outbox>
# It shows the whole draft, asks you to type yes, then writes <draft>.approved holding the
# draft's fingerprint. If the draft is edited afterwards the fingerprint no longer matches,
# and your agent must treat it as NOT approved. The phone cannot do this step.
# Env: COGENT_HOME (default ~/cogent).
set -u
umask 077
COGENT="${COGENT_HOME:-$HOME/cogent}"
OUT="$COGENT/outbox"
name="${1:-}"
case "$name" in ""|*/*|*.approved) echo "Usage: outbox-approve.sh <draft file name, no folder>" >&2; exit 1;; esac
f="$OUT/$name"
[ -f "$f" ] || { echo "No such draft: $f" >&2; exit 1; }
if [ -e "$COGENT/STOP" ]; then echo "STOP file present. Not approving anything." >&2; exit 1; fi

echo "=============== $name ==============="
cat "$f"
echo "====================================="
echo "Approving means your agent may do exactly the action above, once."
printf 'Type yes to approve, anything else to cancel: '
read -r answer
if [ "$answer" != "yes" ]; then echo "Cancelled. Nothing approved."; exit 1; fi
sum=$(shasum -a 256 "$f" | cut -d' ' -f1)
printf '%s\n' "$sum" > "$f.approved"
echo "Approved. Now tell your agent: approved $name"
