---
name: plan-first
description: Write a short plan for a task and wait for the user's explicit approval before changing anything. Use when the user types /plan-first, or before any task that touches several files or cannot easily be undone.
---
# /plan-first

Start by saying: "Plan first. I will not change anything until you say yes."

1. Restate the task in one sentence, in your own words, so the user can correct you.
2. Look around read-only: read the files you need, list folders, check git status. Do not edit, create, move or delete anything in this step. Never open secret files.
3. Write the plan:
   - **Goal:** one sentence.
   - **Steps:** a numbered list. Each step says what changes, in which file, in plain words.
   - **Files touched:** a list. Say which already exist and which are new.
   - **Risks:** what could go wrong, and anything that cannot be undone. Write "None that I can see." only if that is true.
   - **How to undo:** the exact way to go back (a backup copy, or a git command).
   - **How we will check it worked:** one harmless test.
4. Ask: "Do you want me to go ahead? Reply yes, or tell me what to change."
5. Wait. Only a clear yes counts. Silence, "maybe" or "ok but" do not. If she asks for changes, rewrite the plan and ask again.
6. After a yes, do the steps one at a time, saying what you did after each. Stop and tell her if anything differs from the plan.
