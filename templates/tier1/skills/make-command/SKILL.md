---
name: make-command
description: Turn the task just done into a new command of her own (a skill), shown in full and saved only after she says yes. Use when the user types /make-command or says "make this a command".
---
# /make-command

Start by saying: "Turning what we just did into a command. I will show you the whole file before I save anything."

1. Look back over this session and find the task she means. If more than one task fits, or none does, ask which one. Do not guess.
2. Pick a short name: lowercase letters, digits and dashes, no spaces (for example `weekly-tidy`). Check `ls ~/.claude/skills/` so the name is not taken. If it is taken, pick another and say so. Never overwrite an existing skill.
3. Write the file `~/.claude/skills/<name>/SKILL.md` in this form:
   - A first block between two lines of three dashes, holding `name:` (the name) and `description:` (one sentence on what it does and when to use it, ending with "Use when the user types /<name> or asks for this task.").
   - A heading `# /<name>`.
   - A first line to say out loud when it starts.
   - Numbered steps in plain words, written so a fresh session could do the task without having seen this one. Leave out one-off details (this week's dates, this file's name) and ask for them at the start of the command instead.
   - Any check that proved the task worked, and any limit from this session (for example "show the draft first; never send it").
4. Never put a password, key, account number or private detail in the file. Never write a step that skips a permission prompt, changes settings, or turns off a rule.
5. Show her the name and the complete file, exactly as it would be saved. Say: "This becomes the command `/<name>`. Do you want me to save it? Reply yes, or tell me what to change."
6. Only a clear yes counts. If she asks for changes, rewrite and show it again. On a yes, save it with your Write tool (it asks her again; that is expected). If the folder ~/cogent/playbooks exists, also save the same steps as ~/cogent/playbooks/<name>.md in the form `# <Name>`, then `Trigger:`, numbered `Steps:`, `Checks:` and `Last used:` (today's date), and add a line to ~/cogent/brain/log.md. Say where both were saved.
7. Tell her where it was saved and how to use it: type `/<name>` in a new session, or restart Claude Code if it is not in the list when she types `/`. Tell her how to remove it: `rm -r ~/.claude/skills/<name>` in her own Terminal.
