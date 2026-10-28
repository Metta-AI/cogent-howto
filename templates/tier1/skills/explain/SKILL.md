---
name: explain
description: Explain in plain words what is in front of us (a file, a folder, an error message, a command, or a setting) so a non-programmer can understand it. Use when the user types /explain or asks what something is or means.
---
# /explain

Start by saying: "Explaining this in plain words."

1. Work out what the user means. If they named a file, folder or message, look at it. If they did not, ask what they want explained. Do not guess.
2. Read only what you need. Never open secret files (.env, anything in ~/.ssh or ~/.aws, key files). If the thing to explain is one of those, say so and stop.
3. Answer in this order, using plain words and short sentences:
   - **What it is**, in one or two sentences.
   - **What it does or why it is here**, in a few sentences.
   - **Anything to watch**, such as a risk, a cost, or something that looks wrong. Write "Nothing stands out." if there is nothing.
4. Define any technical word the first time you use it, in a few words.
5. End by asking whether she wants more detail on any part. Do not change any file while explaining.
