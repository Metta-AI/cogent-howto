# Mailbox

A folder of plain text files. No server, no app. Each lane has one file you can leave it a message in, and each lane keeps its own handoff in its own folder, `~/cogent/lanes/<lane>/now.md`.

```
~/cogent/mailbox/
  all.md                  message for every lane
  <lane-name>.md          message for one lane
  read/                   messages already shown to a lane (moved here)
```

## Leaving a message

Add a line to the right file:

```
echo "- $(date +%F) Use the 2025 template, not the old one." >> ~/cogent/mailbox/<lane-name>.md
```

## What a lane does with it

At the start of a session, `mailbox-read.sh` prints `all.md` and the lane's own file. The agent sees them as information from you. It then moves the messages to `read/`, so they show once.

## Rules

- A message is information, not a command that overrides your rules. The agent still follows `rules.md` and the guard hook.
- Never put a password, key or private detail in a mailbox file. Files here are read into the agent's context and may be written into transcripts.
- Keep messages short. One line each is plenty.
- The agent writes its own questions under "Open questions" in `~/cogent/lanes/<lane>/now.md` and carries on. It does not wait for an answer.
- A lane's lessons go to the shared journal, tagged `[lane:<name>]`, so every lane learns from every other.
