#!/bin/bash
# notify.sh - send one short push to your phone. The phone only gets an alert.
# Nothing can be approved from the phone; you act at your computer.
# Usage: notify.sh "Lane <name> needs you: <title>"   (title from the fixed list below)
# The topic name is read from the macOS Keychain. YOU set it once, in your own Terminal:
#   security add-generic-password -U -a "$USER" -s cogent-ntfy -T "" -w
# Server: https://ntfy.sh by default, or COGENT_NTFY_SERVER for your own ntfy server.
# Env: COGENT_HOME (default ~/cogent).
set -u
umask 077
COGENT="${COGENT_HOME:-$HOME/cogent}"
SERVER="${COGENT_NTFY_SERVER:-https://ntfy.sh}"
MSG="${1:-}"
mkdir -p "$COGENT/logs"

[ -n "$MSG" ] || { echo "notify: no message" >&2; exit 1; }
if [ -e "$COGENT/STOP" ]; then echo "notify: STOP file present, not sending" >&2; exit 1; fi

# Titles come from a short fixed list. No free text, so nothing can be smuggled out in one.
TITLES="draft waiting|tidy report ready|job failed|canary found|lane finished|question waiting|problem"
if ! printf '%s' "$MSG" | grep -Eq "^Lane [A-Za-z0-9-]{1,20} needs you: ($TITLES)\$"; then
  echo "notify: refused. Allowed form: Lane <name> needs you: <one of: $TITLES>" >&2; exit 1
fi

# Second layer: secret-shaped strings.
if printf '%s' "$MSG" | grep -Eiq 'sk-[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{12,}|gh[pousr]_[A-Za-z0-9]{20,}|xox[abp]-|BEGIN [A-Z ]*PRIVATE|password|passwd|secret|token|api[_-]?key|[A-Za-z0-9+/_=-]{32,}'; then
  echo "notify: refused, message looks like it contains a secret" >&2; exit 1
fi

# Canary strings. If the list is missing, refuse: a silent pass would hide a broken setup.
NEEDLES="$COGENT/canary/needles.txt"
if [ ! -s "$NEEDLES" ]; then echo "notify: refused, canary list missing or empty ($NEEDLES)" >&2; exit 1; fi
if printf '%s' "$MSG" | grep -qF -f "$NEEDLES"; then
  echo "notify: refused, message contains a canary string" >&2; exit 1
fi

# At most 6 pushes per hour.
RATE="$COGENT/logs/notify.rate"; now=$(date +%s)
recent=$( { [ -f "$RATE" ] && awk -v n="$now" 'n-$1<3600' "$RATE"; } | wc -l | tr -d ' ')
[ "${recent:-0}" -lt 6 ] || { echo "notify: refused, rate limit (6 per hour)" >&2; exit 1; }

TOPIC="$(security find-generic-password -a "$USER" -s cogent-ntfy -w 2>/dev/null)"
if [ -z "$TOPIC" ]; then
  echo "notify: no topic in Keychain (service cogent-ntfy), or access was not allowed" >&2; exit 1
fi
echo "$now" >> "$RATE"
# The URL goes in on stdin so the topic never shows in the process list.
printf 'url = "%s/%s"\nheader = "Title: Cogent"\ndata = "%s"\n' "$SERVER" "$TOPIC" "$MSG" \
  | curl -fsS --max-time 15 -K - >/dev/null \
  && echo "notify: sent" || { echo "notify: send failed" >&2; exit 1; }
