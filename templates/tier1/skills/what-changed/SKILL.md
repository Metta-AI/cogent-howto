---
name: what-changed
description: Show and explain every change since the last git commit, in plain words, before the user approves a commit. Use when the user types /what-changed or is about to commit.
---
# /what-changed

Start by saying: "Showing everything that changed since the last commit."

1. Run `git status --short` and `git diff HEAD --stat`. If this is not a git folder, say so and stop.
2. For each changed file, run `git diff HEAD -- <file>` and read it. For new files that git does not track yet, read the file. Never print the contents of secret files (.env, key files). If one of them changed, say only that it changed.
3. Report, one file at a time:
   - The file name and whether it is new, changed, or deleted.
   - What changed, in one or two plain sentences. No line-by-line dumps.
   - Whether the change was asked for. If you did not expect a change, say so clearly.
4. Then give a short summary: how many files, anything risky (deleted files, secrets, settings or permission changes, large files), and anything that should not be committed.
5. Ask: "Do you want me to commit these? I can commit everything, or only some files." Do not commit until she says yes. Suggest a commit message in plain words and let her change it.
