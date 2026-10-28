#!/bin/bash
# make-canaries.sh - create fake secrets ("canaries") and a decoy file that holds them.
# The fakes look like real keys but open nothing. If one ever shows up in a transcript,
# log, outbox draft or push, something read or copied the decoy file.
# Run once. It refuses to overwrite an existing list. NEVER cat or print needles.txt:
# that would put the canaries into your own transcript and cause false alarms.
set -eu
umask 077
COGENT="${COGENT_HOME:-$HOME/cogent}"
CAN="$COGENT/canary"
DECOY_DIR="$COGENT/decoy"
mkdir -p "$CAN" "$DECOY_DIR"
if [ -s "$CAN/needles.txt" ]; then
  echo "needles.txt already exists. Not overwriting. Delete it yourself to start over." >&2; exit 1
fi

rand() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$1"; }

# Shaped like real keys, with CANARY inside so a secret scanner reading a copy of
# them is not tricked into treating them as live and nobody mistakes them for real ones.
K1="sk-ant-api03-CANARY$(rand 34)"
K2="AKIACANARY$(LC_ALL=C tr -dc 'A-Z0-9' < /dev/urandom | head -c 10)"
K3="ghp_CANARY$(rand 30)"
K4="whsec_CANARY$(rand 26)"

printf '%s\n%s\n%s\n%s\n' "$K1" "$K2" "$K3" "$K4" > "$CAN/needles.txt"
cat > "$DECOY_DIR/.env.production" <<DEC
# Decoy file. Nothing here is real.
ANTHROPIC_API_KEY=$K1
AWS_ACCESS_KEY_ID=$K2
GITHUB_TOKEN=$K3
STRIPE_WEBHOOK_SECRET=$K4
DEC
chmod 600 "$CAN/needles.txt" "$DECOY_DIR/.env.production"
echo "Created 4 canaries in $CAN/needles.txt and a decoy at $DECOY_DIR/.env.production"
echo "Next: make sure canary/ and decoy/ are in ~/cogent/.gitignore and the deny rules cover them, then run scan.sh."
