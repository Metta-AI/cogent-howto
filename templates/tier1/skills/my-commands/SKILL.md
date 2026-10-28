---
name: my-commands
description: List every command (skill) she has, with a one-line description each, split into starters and ones made for her. Use when the user types /my-commands or asks "what can you do?" or "what commands do I have?".
---
# /my-commands

Start by saying: "Here are the commands you have."

1. List the folders in ~/.claude/skills with `ls ~/.claude/skills/`. Read the first block (between the lines of three dashes) of each `SKILL.md` for `name:` and `description:`. Read nothing else.
2. Sort them into two groups:
   - **Starters:** `explain`, `plan-first`, `what-changed`, `wrap-up`, `make-command`, `draft`, `summarize`, `tidy-sheet`, `my-commands`.
   - **Made for you:** every other skill. These were made with make-command. If there are none, write "None yet."
3. Show each group as a list: `/name`: the description cut to one short plain sentence (the part before "Use when"). Do not change any file. If a skill has no readable description, list it and say "no description".
4. End with exactly: Make a new one: say 'make this a command'.
