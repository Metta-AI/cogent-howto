# Tier 1 build: a coding agent that knows you

Read `00-read-me-first.md` first. Its rules apply to every step here.

**Goal.** Her cogent's foundation: one workspace folder under git, its soul (`soul.md`, who it is and who it works for), its brain (a plain folder of notes that loads at the start of every session), a thin personal profile with her rules, safe settings, private folders walled off, the sandbox on, nine starter commands (skills), and Evangeline knowing the controls that are specific to her cogent.

**Time.** About 2 to 3 hours.

In this file, `PKG` means `~/cogent/howto`, the folder that holds `templates/`. You run from `~/cogent` (the restart in step e of `00-read-me-first.md` puts you there). Write `~/cogent/howto` wherever a command says `PKG`.

## Step 0: Claude Code is already installed and signed in

She already uses Claude Code, so nothing is installed here. Check it with `claude --version` (it prints a version number; the prerequisites below run it). `00-read-me-first.md` has already copied the package to `~/cogent/howto` and restarted her in `~/cogent`. If `pwd` does not show `~/cogent`, or `ls ~/cogent/howto` does not show `CHEATSHEET.md`, `for-your-agent`, `checklists` and `templates`, stop and tell her what you see. You take over from step 1.

## Prerequisites check

Run these (read-only) and report the results to her.

```bash
uname -s
sw_vers -productVersion
claude --version
git --version
echo "$HOME"
pwd
ls ~/cogent/howto/templates/tier1 | wc -l
test -s ~/cogent/soul.md && echo "soul.md: yes" || echo "soul.md: no"
test -d ~/cogent/brain && echo "brain: yes" || echo "brain: no"
test -f ~/.claude/settings.json && echo "settings.json EXISTS (merge, do not overwrite)" || echo "no settings.json yet"
test -f ~/.claude/CLAUDE.md && echo "CLAUDE.md EXISTS (append, do not overwrite)" || echo "no CLAUDE.md yet"
ls -A ~/cogent | head -20
[ -n "${ANTHROPIC_API_KEY:-}" ] && echo "ANTHROPIC_API_KEY is set" || echo "ANTHROPIC_API_KEY is not set"
```

Expected: `Darwin`; macOS 13 or newer; a Claude Code version number; a git version (if macOS offers to install "command line developer tools", that is Apple's own installer; she says yes and waits, then you rerun); the real home path; `pwd` shows `~/cogent` (her home path followed by `/cogent`); the template count is `8` (CLAUDE.md, bin, brain, gitignore, settings.json, skills, soul.md, workspace-CLAUDE.md: it counts the items in the folder, not the skills); `soul.md: yes` and `brain: yes` if onboarding is done (step 2b checks them); `ls -A ~/cogent` shows `BUILD-LOG.md`, `CLAUDE.md`, `brain`, `howto`, `onboarding.md` and `soul.md` (made by `00-read-me-first.md` and onboarding), and possibly `.claude` (Claude Code's own folder for this workspace). Anything else: stop and ask her what it is. Optional: she can run `claude doctor` in her own Terminal if she wants a health check; it is interactive and may use the network, so you do not run it.

Do not print the key. The last line only says whether the variable exists. If it is set, tell her: with that variable set, Claude Code can use that key instead of her login. Ask whether that is on purpose. Do not edit her shell files; tell her the line to look for.

Also run the tier detection from `00-read-me-first.md`. If Tier 1 is fully built, say so and stop. If it is part built, follow the two-choice rule in that file.

**Files this tier creates or changes**

| File or folder | What it is |
|---|---|
| `~/cogent/` | Her workspace folder (it exists already; this tier puts it under git) |
| `~/cogent/.gitignore` | Keeps secrets, logs, `drafts/` and `work/` out of git |
| `~/cogent/soul.md` | Who the cogent is and who it works for, first person (written at onboarding) |
| `~/cogent/brain/` | Its notes: `index.md`, `now.md`, `failed.md`, `gotchas.md`, `rules.md`, `claims.md`, `ideas.md`, `log.md`, `journal/` and `handoff/` |
| `~/cogent/bin/brain-load.sh` | The small program that shows the cogent its soul and brain at the start of every session |
| `~/cogent/BUILD-LOG.md` | The build log |
| `~/cogent/backups/` | Copies of any file before it is changed (kept out of git) |
| `~/.claude/settings.json` | Safe settings, and the one start-up hook that loads the brain (merged if it exists) |
| `~/.claude/CLAUDE.md` | Her thin personal profile: working rules, hard rules and where to find the brain (appended to if it exists) |
| `~/.claude/skills/explain/SKILL.md` | The `/explain` skill |
| `~/.claude/skills/plan-first/SKILL.md` | The `/plan-first` skill |
| `~/.claude/skills/what-changed/SKILL.md` | The `/what-changed` skill |
| `~/.claude/skills/wrap-up/SKILL.md` | The `/wrap-up` skill |
| `~/.claude/skills/make-command/SKILL.md` | The `/make-command` skill ("make this a command") |
| `~/.claude/skills/draft/SKILL.md` | The `/draft` skill (writes in her voice, never sends) |
| `~/.claude/skills/summarize/SKILL.md` | The `/summarize` skill |
| `~/.claude/skills/tidy-sheet/SKILL.md` | The `/tidy-sheet` skill (works on a copy) |
| `~/.claude/skills/my-commands/SKILL.md` | The `/my-commands` skill (lists what she can ask for) |

**What this tier does not touch.** Her shell files (`~/.zshrc` and similar), any project folders, her keys and secrets, `~/.claude.json` (which Claude Code writes itself), her browser, any folder outside `~/cogent` (except to wall it off), and anything outside the list above. One hook only (it runs `brain-load.sh`, which reads files and prints them). No MCP servers, no network access beyond Claude Code's own connection.

## Step 1: Confirm the sign-in

**Why:** She should know which account the cogent runs under.
**Do:** Ask her to type `/status` and read you the login method and plan on the screen.
**Check:** It shows her usual Claude login, not an API key.
**If it fails:** If it shows an API key or Console account, tell her and ask whether that is on purpose. If not, she types `/logout` and `/login` and chooses her usual account. If `/status` does not show the login method, ask her to type `/login` and read you the account line, or to run `claude doctor` in her own Terminal.

## Step 1b: Decide about model training

**Why:** Anthropic gives you a choice about whether your conversations may be used to improve its models. Keeping chats for longer is part of that choice. It is yours to make, and you should make it on purpose.
**Do:** Tell her to open `claude.ai/settings/data-privacy-controls` in her browser (typed by hand), read the setting about helping improve Claude, and decide. As the page stands today, saying yes means chats are kept for up to 5 years; saying no means 30 days. Read it live and tell her if it differs. She changes it herself, in the browser. Do not ask which she picked beyond "decided"; log "training setting decided" without the choice.

> **STOP - checkpoint 0.** Ask: "Have you looked at the training setting and chosen on purpose?" Do not continue without her yes.

**Check:** She says she has chosen.
**If it fails:** If she is unsure, leave it as it is and note it in the build log; she can change it any time.
**Undo:** She changes the setting back on the same page.

## Step 2: Create the workspace folder and put it under git

**Why:** One folder for everything this setup creates. Git keeps a history, so any change can be undone.
**Do:**
1. Ask her for the name and email to put on her commits. Tell her they stay on this computer and she can use any address. Replace `<<HER-NAME>>` and `<<HER-EMAIL>>` below with her answers. If a name contains a double quote, ask for a version without it.
2. Create the folder and start git:
   ```bash
   mkdir -p ~/cogent/backups
   git -C ~/cogent init
   git -C ~/cogent config user.name "<<HER-NAME>>"
   git -C ~/cogent config user.email "<<HER-EMAIL>>"
   cp ~/cogent/howto/templates/tier1/gitignore ~/cogent/.gitignore
   ```
3. `~/cogent/BUILD-LOG.md` and `~/cogent/CLAUDE.md` already exist from `00-read-me-first.md` (if not, create the log with the first line `# Build log`, and copy `templates/tier1/workspace-CLAUDE.md` to `~/cogent/CLAUDE.md`). Write the entries for the prerequisites check, step 1, step 1b and this step, in the format in `00-read-me-first.md`, before you commit.
4. Commit:
   ```bash
   git -C ~/cogent add .gitignore BUILD-LOG.md CLAUDE.md onboarding.md soul.md brain
   git -C ~/cogent commit -m "Start workspace"
   ```

**Check:** `git -C ~/cogent log --oneline` shows one commit (the branch may be called `main` or `master`; either is fine). `git -C ~/cogent ls-files` lists `.gitignore`, `BUILD-LOG.md`, `CLAUDE.md`, `onboarding.md`, `soul.md` and the files in `brain/`. `git -C ~/cogent status --short` shows nothing: the `howto/` and `backups/` folders are listed in `.gitignore`.
**If it fails:** A "dubious ownership" or "identity unknown" message means the config lines did not run. Rerun them. If `~/cogent` holds anything besides `BUILD-LOG.md`, `CLAUDE.md`, `brain`, `howto`, `onboarding.md`, `soul.md` (and possibly `.claude`, which Claude Code makes itself), stop and ask her what is in it before continuing.
**Undo:** `rm -r ~/cogent/.git ~/cogent/.gitignore ~/cogent/BUILD-LOG.md` (she approves the prompt). That leaves the folder and the package in place.

## Step 2b: Check her soul and the brain files

**Why:** The soul is the first thing the cogent reads in every session. It is written from her answers, and only she changes it. The brain is a plain folder of notes. Both were started at onboarding.
**Do:**
1. Check they exist and are filled in:
   ```bash
   test -s ~/cogent/soul.md && grep -c "<<" ~/cogent/soul.md
   ls ~/cogent/brain ~/cogent/brain/journal
   ```
2. If `~/cogent/soul.md` is missing, stop. Go back to `onboarding.md` (step 4b). Never write identity into `~/.claude/CLAUDE.md`.
3. If `~/cogent/brain` is missing, copy the empty brain and tell her: `cp -R ~/cogent/howto/templates/tier1/brain ~/cogent/brain`. Seed `rules.md` and `now.md` as in `onboarding.md` step 4b, items 4 and 5, if they are still empty.
4. Read her the first lines of the brain files, in one sentence each: `index.md` is the map, with every file and its size limit; `now.md` is where we left off, rewritten every wrap-up; `handoff/` holds a note for unfinished work; the handoff and now.md each carry a time, and the newer one is shown first; `failed.md` is the never-again list, read first; `gotchas.md` holds traps in her work, each with a NEVER line; `rules.md` holds the rules she approved, each with a reason; `claims.md` holds what the cogent believes, each with a confidence (HIGH she said it, MED seen twice, LOW a guess); `ideas.md` holds ideas to try; `log.md` records every write. Say that she can open any of them in a text editor, and that nothing in them is secret.

> **STOP - checkpoint 1a.** Show her `~/cogent/soul.md` in full. Ask one question: "Is this right? Say yes, or tell me what to change." If she names something she does not want written down, take it out. Do not continue without her explicit "yes".

**Check:** `grep -c "<<" ~/cogent/soul.md` prints `0` (it prints `0` and exits with status 1 when there is no match; that is success). `ls ~/cogent/brain` shows `claims.md`, `failed.md`, `gotchas.md`, `handoff`, `ideas.md`, `index.md`, `journal`, `log.md`, `now.md`, `rules.md`.
**If it fails:** A `<<` left in soul.md means a placeholder was not filled. Ask her for that answer and fix it. Missing brain files: copy them from the package as in item 3.
**Undo (she runs it in her own Terminal):** `rm ~/cogent/soul.md` and `rm -r ~/cogent/brain`.

## Step 2c: Install the brain loader

**Why:** A cogent that has to remember to read its notes will sometimes forget. This small program (a script) prints the soul and the brain, so they are in front of the cogent when every session starts.
**Do:**
1. Make the folder and copy the script:
   ```bash
   mkdir -p ~/cogent/bin
   cp ~/cogent/howto/templates/tier1/bin/brain-load.sh ~/cogent/bin/brain-load.sh
   chmod +x ~/cogent/bin/brain-load.sh
   ```
2. Read it to her in plain words: it only reads files in `~/cogent` and prints them. A short load (the usual one) shows soul.md, the newest handoff or now.md, whichever is newer (compared by the time in the handoff's filename and the `updated:` line in now.md; on a tie the handoff wins), the top 8 entries of failed.md, the NEVER lines of gotchas.md, rules.md and the claims marked HIGH. A full load shows every brain file except the archive; it runs when she says "load everything" and at the first session of each week (the script keeps a tiny marker file, `brain/.full-stamp`, to know). Apart from that marker it writes nothing, contacts nothing and always ends without error, so it cannot block a session. It frames the notes as the cogent's own notes, not as orders from outside. It prints nothing when the variable `COGENT_HEADLESS` is `1` (scheduled jobs later), and reads the folder named in `COGENT_HOME` if that is set.
3. Run it once by hand and read her the first lines: `bash ~/cogent/bin/brain-load.sh | head -30`.

**Check:** `bash -n ~/cogent/bin/brain-load.sh && echo syntax ok` prints `syntax ok`. The run in item 3 starts with `==== YOUR OWN NOTES` and shows her soul. `COGENT_HEADLESS=1 bash ~/cogent/bin/brain-load.sh | wc -c` prints `0`. The first run says `FULL load` (no marker yet); a second run says `SLIM load`. `COGENT_LOAD=full bash ~/cogent/bin/brain-load.sh | grep -c "claims"` is 1 or more. To see the handoff rule (the newer of the handoff's filename time and now.md's `updated:` line wins; on a tie the handoff wins): with the Write tool write `~/cogent/brain/handoff/2099-01-01-0000-test.md` and run the loader: expect `newest handoff`. Then write `~/cogent/brain/handoff/2000-01-01-0000-old.md` as well and remove the 2099 one: expect `where we left off` (now.md is newer). Delete both test files (she approves).
**If it fails:** "No such file" means the copy in item 1 did not happen; check `ls ~/cogent/howto/templates/tier1/bin`. "Permission denied" means the `chmod` did not run; the hook calls it with `bash`, so it still works, but rerun the `chmod`.
**Undo:** `rm ~/cogent/bin/brain-load.sh`.

## Step 2d: Save the brain to git

**Why:** The brain is only safe if there is a way back. Git keeps every version.
**Do:**
```bash
git -C ~/cogent add BUILD-LOG.md soul.md brain bin
git -C ~/cogent commit -m "Soul, brain and loader"
```
**Check:** `git -C ~/cogent log --oneline` shows the commit, and `git -C ~/cogent status --short` shows nothing. `git -C ~/cogent ls-files soul.md brain bin` lists the files.
**If it fails:** If git says nothing to commit, there was nothing new since step 2; that is fine.
**Undo:** `git -C ~/cogent reset --soft HEAD~1` (she runs it in her own Terminal). The files stay.

## Step 2e: A one-word way to open your cogent

**Why:** Opening Claude Code "in a folder" is easy to get wrong. This gives her one way to come back to her cogent every time, and a note she can read when she forgets. Read `opens-with:` from `~/cogent/BUILD-LOG.md` (step a3 of `00-read-me-first.md`). If it is missing, ask step a3's question now and log the answer.
**Do (opens-with: terminal):**
1. Tell her: "I can add a shortcut to a settings file your Terminal reads when it opens, called `.zshrc`. After that you type the word `cogent` in a new Terminal window and your cogent opens, in the right folder. Okay?" Wait for her yes.
2. Back up and check for an existing line (this only reads and copies):
   ```bash
   mkdir -p ~/cogent/backups
   test -f ~/.zshrc && cp ~/.zshrc ~/cogent/backups/zshrc.bak-$(date +%Y%m%d)
   grep -n "alias cogent=" ~/.zshrc 2>/dev/null || echo "no cogent alias yet"
   ```
   If the backup name already exists, add a letter (`...bak-20261027b`). If the grep shows a line that is exactly `alias cogent='cd ~/cogent && claude'`, it is already there: do not add it again, go to the check. If it shows any other `alias cogent=` line, stop and tell her what it says.
3. Show her the one line you will add: `alias cogent='cd ~/cogent && claude'`. With her yes, add it to the end of `~/.zshrc` with your Write or Edit tool (rule 14; it asks her). If `~/.zshrc` does not exist, create it with just that line. Keep every other line as it is.
4. Tell her: "Now open a new Terminal window. In Terminal's menu bar choose Shell, then New Window. Type `cogent` and press Enter." She does this herself. Terminal windows that were already open do not know the shortcut yet.
**Do (opens-with: desktop):**
1. Tell her: "We will open the cogent folder once in the Claude desktop app, so the app remembers it." Do not name menus or buttons from memory. Ask her what she sees on the screen, one short question at a time (for example "What do you see at the top or on the left of the Claude window?"), and guide her from her answer toward starting a new Claude Code session and choosing the folder called `cogent` in her home folder (the one with the house icon in Finder). If what she describes does not match, ask again. Do not guess.
2. When the session has opened in the cogent folder, ask her what the window shows as the folder name. Tell her the app usually lists a folder you have opened before under its recent folders, so next time she can pick `cogent` from that list. Ask her to look and tell you whether she sees it there. Write down what she saw.
**Either way, write her note.** Show her the two lines, in her words, and with her yes write `~/cogent/HOW-TO-OPEN-ME.md`. Terminal version:
```
To open my cogent: open a new Terminal window, type cogent and press Enter.
If that does not work: type  cd ~/cogent && claude  and press Enter.
```
Desktop version (use the words she used for what she clicked, and for where she saw the folder):
```
To open my cogent: open the Claude app, start a new Claude Code session and choose the folder called cogent.
If I cannot find it: it is in my home folder (the house icon in Finder), and the app lists it under recent folders.
```
Then log the step and commit: `git -C ~/cogent add HOW-TO-OPEN-ME.md BUILD-LOG.md && git -C ~/cogent commit -m "How to open my cogent"`.
**From here on,** every restart instruction you give her uses this way: terminal, "Type /exit and press Enter. Open a new Terminal window, type `cogent` and press Enter. Then type: continue setting up my cogent." Desktop, the wording in step a3 of `00-read-me-first.md`, adding that she can pick `cogent` from the recent folders if the app lists it.

**Check:** (terminal) in the new window, after she types `cogent`, ask her to type `pwd` and read it to you; it must end in `/cogent`. Also `grep -c "alias cogent=" ~/.zshrc` prints `1`. (desktop) the session's `pwd` ends in `/cogent`. Both: `test -s ~/cogent/HOW-TO-OPEN-ME.md && echo ok` prints `ok`.
**If it fails:** If Terminal says `command not found: cogent`, she opened the window before the line was added, or it is not in the file: close it, open a new one, and check `grep -n "alias cogent=" ~/.zshrc`. If it still fails, use the `cd ~/cogent && claude` line from her note and tell her the shortcut is not working yet.
**Undo:** (terminal) restore the backup in her own Terminal: `cp ~/cogent/backups/zshrc.bak-YYYYMMDD ~/.zshrc`. If there was no `.zshrc` before, remove just the line: `grep -v "alias cogent=" ~/.zshrc > ~/cogent/backups/zshrc.new && cp ~/cogent/backups/zshrc.new ~/.zshrc`. Then `rm ~/cogent/HOW-TO-OPEN-ME.md`.

## Step 3: Safe settings

**Why:** This is the set of rules that stays on even if the agent makes a mistake: ask before risky actions, never read secret files, no bypass mode, less data kept.
**Do:**
1. Read `~/cogent/howto/templates/tier1/settings.json` to her. Say each part below in one short line; give more only if she asks:
   - `defaultMode: "default"`: ask before acting.
   - `disableBypassPermissionsMode` and `disableAutoMode`: the two modes that skip prompts are switched off.
   - `deny`: reading `.env` files, `~/.ssh`, `~/.aws`, Google cloud credentials, Keychain files, other credential files, browser and mail folders, `.pem`, `.key` and `id_rsa` files; reading and editing the private folders you wall off in step 3b; printing the Keychain password or environment variables; all `mcp__*` tools (outside connections). A deny rule always wins.
   - `ask`: git push, curl, wget, rm, sudo, installing software, npx, `osascript`, `launchctl`, `crontab`, `git remote`, `defaults`, and every use of the two web tools, WebFetch and WebSearch. Claude Code stops and asks every time. Be honest with her: these rules match the text of the command, so an unusual spelling (for example `git -C folder push`) may slip past the match. That is one reason Tier 2 adds hooks that look harder.
   - `env`: five switches that turn off telemetry (usage reporting) and non-essential network traffic. Her prompts and the agent's answers still go to Anthropic; that cannot be turned off.
   - `hooks`: one SessionStart hook. When a session starts, Claude Code runs `brain-load.sh`, so the soul and brain are shown to the cogent first. It has a 10 second limit. If the script is missing or broken, the session still starts and the cogent falls back to reading the files itself (a rule in the profile says so).
   - `cleanupPeriodDays: 14`: conversation logs on her computer are deleted after 14 days. These logs are plain text.
   - `sandbox`: on, with no internet domains allowed, no automatic approval of sandboxed commands, no quiet retry outside the sandbox, and a list of folders commands cannot read (explained in steps 3b and 5).
2. The template has the text `__HOME__` in the hook path. Fill it with her home path: `sed "s|__HOME__|$HOME|g" ~/cogent/howto/templates/tier1/settings.json > ~/cogent/backups/settings.tier1.filled.json`, then check `grep -c "__HOME__" ~/cogent/backups/settings.tier1.filled.json` prints `0`. If `~/.claude/settings.json` does not exist: read the filled copy and write its exact contents to `~/.claude/settings.json` with your Write tool (it asks her; that is expected).
3. If it exists: follow "Existing files: merge, do not overwrite" in `00-read-me-first.md`, merging from the filled copy, and show her the `diff`. If she already has a `SessionStart` hook, keep hers and add this one next to it.
4. Validate: `python3 -m json.tool ~/.claude/settings.json > /dev/null && echo valid`.

> **STOP - checkpoint 1.** Show her the final contents of `~/.claude/settings.json` (or the diff, if you merged). Ask one question: "May I keep these settings?" Add that she can undo them by copying the backup back. Do not continue without her explicit "yes".

**Check:** Ask her to type `/hooks` and read you whether a SessionStart hook that runs `brain-load.sh` is listed. Ask her to type `/status` and read you the "Setting sources" line (the user settings file should be listed). Ask her to type `/permissions` and read you a few of the deny and ask rules, including `Read(~/Documents/**)` and `WebFetch`. Settings reload by themselves; if `/permissions` does not show them, update `brain/now.md` first (`updated:` line, Stopped at: `Tier 1, step 3: check /permissions after restart`), then she types `/exit` and you give her the restart words for her way of opening Claude Code (step 2e). If the labels on screen differ from the ones named here, she reads you whatever lists the settings files and the rules. Stop only if no deny rule shows. If a deny rule still does not appear in `/permissions`, stop. Do not go on to step 9.
**If it fails:** If Claude Code reports a settings error, the JSON is invalid or a key is misspelled. Have her restore the backup in her own Terminal (`cp ~/cogent/backups/settings.json.bak-YYYYMMDD ~/.claude/settings.json`) or, if there was none, delete the file, and tell her the exact message.
**Undo (she runs it in her own Terminal):** `cp ~/cogent/backups/settings.json.bak-YYYYMMDD ~/.claude/settings.json`. If there was no earlier file: `rm ~/.claude/settings.json`.

## Step 3b: Wall off private folders

**Why:** Whatever the agent reads is sent to the model and saved in a log on this computer. The best protection for your private papers is that it cannot open them at all. You decide which folders are walled off.
**Do:**
1. Tell her: the settings you just saved already wall off `~/Documents`, `~/Desktop`, `~/Downloads`, `~/Pictures` and `~/Library` (which also holds mail, messages, browser data and iCloud Drive files). Walls are enforced two ways. The permission rules (`Read(~/Documents/**)` and `Edit(~/Documents/**)`) stop the agent's file tools: reading, searching and editing. The sandbox list (`sandbox.filesystem.denyRead`) stops shell commands. Both lists must name the same folders.
2. First read the "Off limits" line in `~/cogent/soul.md`. If it names folders or files (for example HR files), ask where they live and wall that folder, with her yes. Then ask: "Which other folders hold things this agent should never see? For example `~/Movies`, `~/Music`, a folder from Dropbox or a work drive, or a folder of client files." Also ask whether she wants any folder on the default list taken off it. Warn her: taking a folder off lets the agent read it.
3. For each folder she adds, add one `Read(PATH/**)` and one `Edit(PATH/**)` to `permissions.deny` and the folder to `sandbox.filesystem.denyRead`, using `~/` paths. Back up `~/.claude/settings.json` into `~/cogent/backups/` first. Make the edit with your Edit tool (it asks her). Record the folder names in the build log. Names only.
4. Tell her how to use a file from a walled folder: she copies the file into `~/cogent/` herself (Finder, or `cp` in her own Terminal). Then the agent can work on the copy. A deny rule always wins, so there is no way to let it read one file inside a walled folder; copying is the way.
5. Validate: `python3 -m json.tool ~/.claude/settings.json > /dev/null && echo valid`. Show the `diff` against the backup.

> **STOP - checkpoint 1b.** Show her the final list of walled folders, in plain words, and say: "The agent cannot read or change anything in these folders, and shell commands cannot read them either. To work on a file from one, you copy it into ~/cogent first." Ask one question: "May I save this list?" Do not continue without her yes.

**Check (a harmless test, with `~/Documents`, or the first folder she added if she added any, called FOLDER below):**
- File tool: use the Read tool on `FOLDER/wall-test.txt` (this file does not exist and you must not create it). Expected: refused by a permission rule, not "file not found".
- Shell: run `ls FOLDER`. Expected: refused, usually with "Operation not permitted" or a sandbox message. If it prints a listing, do not read the names aloud: stop, tell her, and see "If it fails".
Report both results exactly.
**If it fails:** If the shell test succeeds, update `brain/now.md` first (`updated:` line, Stopped at: `Tier 1, step 3b: retry the wall test after restart`), then give her the restart words for her way of opening Claude Code (step 2e), and retry once (sandbox settings may need a restart). If it still succeeds, stop; do not go on to step 5. If ordinary commands start failing with errors that mention `~/Library`, tell her which command; with her yes you may remove only `~/Library` from `sandbox.filesystem.denyRead`, and keep the file-tool rule. Say plainly that this leaves shell commands able to read it.
**Undo:** Restore the settings backup (she runs the `cp` from step 3 in her own Terminal).

## Step 4: Her personal profile

**Why:** `CLAUDE.md` is the page Claude Code reads at the start of every session. In her cogent it is thin on purpose. Who the cogent is and who she is live in `soul.md`. What it remembers lives in the brain. The profile holds the working rules (each with a reason), the hard rules, and where to find the soul and brain if the loader fails. It guides the agent but does not enforce anything; the settings and (in Tier 2) the hooks do that.
**Do:**
1. Check `soul.md` exists (`test -s ~/cogent/soul.md`); if not, stop and run `onboarding.md` first. The template `~/cogent/howto/templates/tier1/CLAUDE.md` has no placeholders and no identity. Do not copy her name, manner or answers into it.
2. Show her the template in full: the read order, the rule that soul.md changes only on her request, the Advisor rule (answer with the verdict first, then how sure it is, then the source file, and say "I don't know" when the brain does not), the hard rules, the working rules and the habit rules, each with its reason. Ask whether any rule is wrong for her. Change, add or remove rules as she says. Each rule keeps a reason.
3. Write it with your Write tool, not Bash. If `~/.claude/CLAUDE.md` exists, copy it into `~/cogent/backups/` first and append the new text under a line `# Added YYYY-MM-DD from the cogent how-to`. Otherwise write the new file.

> **STOP - checkpoint 2.** Show her the final `~/.claude/CLAUDE.md`. Ask: "Is everything in this file right for you?" Do not write it until she says yes.

**Check:** `grep -c "<<" ~/.claude/CLAUDE.md` prints `0` (it prints `0` and exits with status 1 when there is no match; that is success). `grep -c "COGENT-NAME\|HER-NAME" ~/.claude/CLAUDE.md` also prints `0`: no identity lives here. The full test (a fresh session that loads the brain) is in the verification, tests 11 and 12.
**If it fails:** If a `<<` placeholder is left, you copied the wrong file or an old version; recopy the template. If the agent does not seem to know the profile, ask her to type `/memory` and read you whether the file is listed.
**Undo (she runs it):** `cp ~/cogent/backups/CLAUDE.md.bak-YYYYMMDD ~/.claude/CLAUDE.md`, or `rm ~/.claude/CLAUDE.md` if it was new.

## Step 5: Turn on the sandbox

**Why:** The sandbox is an Apple-built fence around the commands the agent runs. It limits where commands can write and which internet sites they can reach.
**Do:**
1. Tell her what it does, in these honest words: "Shell commands can write only in ~/cogent and in temporary folders. Commands can reach only internet sites on a list, and the list is empty. My file-editing tool and the web tools are outside that fence, so they ask you every time."
2. Ask her to type `/sandbox` and read you what the panel offers. The settings file already turns it on with an empty network list, no automatic approval of sandboxed commands, and no quiet retry outside the sandbox. If the panel asks for a mode, she picks the one whose description says commands still go through normal permission prompts. If it is unclear, she reads both descriptions to you and you stop and ask her.
3. Do not add any internet domain to the list now.

**Check:** She reads you that `/sandbox` shows it as enabled. Run `mkdir -p ~/cogent/test-dummy`; it should show a permission prompt (a command that makes something is not auto-approved). She answers yes; it works. If no prompt appears, tell her: automatic approval may be in force, and it should not be. Then run `curl --head https://example.com` and expect two things: the `ask` rule prompts first (she answers no, or yes once to see it fail); if she says yes, the connection should fail with an error such as "blocked by sandbox" or "could not resolve host". Report the exact text. Any success is a stop.
**If it fails:** If `/sandbox` says it is not available or reports a missing piece, tell her the exact message and stop. Do not turn the sandbox off to get past it. If a normal command fails with a sandbox error, tell her which command and ask before changing anything.
**Undo:** She types `/sandbox` and turns it off, or the `sandbox` block is removed from `~/.claude/settings.json` (restore the backup).

## Step 6: Auto-memory

**Why:** Claude Code can keep its own notes about you and your projects between sessions. It is useful, and she should know it exists and where it lives. Her cogent's own brain (`~/cogent/brain`) is the source of truth; auto-memory is a second, quieter notebook that she cannot easily read.
**Do:** Ask her to type `/memory`. Ask her to look for an auto-memory on/off toggle and read her what it says, including the folder where notes are saved. Do not assume the setting name; report what you see. Say that the cogent is told to save lessons to the brain, not to auto-memory. Tell her: the notes are plain files on this computer (under `~/.claude/projects/`), the start of the notes file is loaded into each session, and nothing deletes them automatically. She can open and edit them, and she decides whether it stays on.

> **STOP - checkpoint 3.** Say what auto-memory is, where its files are, and what the toggle currently shows. Ask: "Do you want auto-memory on or off for now?" She sets it, using the toggle in `/memory`, only as she decides. If you cannot find a toggle, say so and leave it as it is.

**Check:** She types `/memory` and reads you that it shows the state she chose.
**If it fails:** If the menu looks different from this guide, describe it to her and let her decide. Do not edit hidden files to force it.
**Undo:** Flip the toggle back in `/memory`.

## Step 7: Nine starter skills

**Why:** A skill is a short instruction file that Claude Code can run when you type a command. These nine make the cogent explain itself, plan before acting, show changes before a commit, save what was learned to the brain at the end of a session, turn a task she did into a command of her own, write drafts in her voice (never sending them), summarize a document or thread, tidy a copy of a spreadsheet, and list every command she has.
**Do:**
1. Name each in one line: `/explain`, `/plan-first`, `/what-changed`, `/wrap-up`, `/make-command` (also "make this a command"), `/draft`, `/summarize`, `/tidy-sheet`, `/my-commands` (also "what can you do?"), each with what it does in a few words (see the Why above).
2. Offer to show any of the nine files in full (`~/cogent/howto/templates/tier1/skills/NAME/SKILL.md`); show the ones she asks for. Each write below also shows her the whole file in the permission prompt.
3. Write them after her yes. For each of the nine names, read `~/cogent/howto/templates/tier1/skills/NAME/SKILL.md` and write its exact contents to `~/.claude/skills/NAME/SKILL.md` with your Write tool (it asks her each time). If a skill of that name already exists, first copy it: `mkdir -p ~/cogent/backups && cp -R ~/.claude/skills/NAME ~/cogent/backups/NAME.bak-YYYYMMDD`, and tell her.

**Check:** `ls ~/.claude/skills/{explain,plan-first,what-changed,wrap-up,make-command,draft,summarize,tidy-sheet,my-commands}/SKILL.md 2>/dev/null | wc -l` prints `9`. Ask her to type `/` and read you whether `explain`, `plan-first`, `what-changed`, `wrap-up`, `make-command`, `draft`, `summarize`, `tidy-sheet` and `my-commands` are in the list. If they are not, she restarts Claude Code.
**If it fails:** A skill missing from the list usually means the folder name or file name is wrong (it must be `SKILL.md`, in capitals) or Claude Code needs a restart.
**Undo (she runs it in her own Terminal):** `rm -r ~/.claude/skills/explain ~/.claude/skills/plan-first ~/.claude/skills/what-changed ~/.claude/skills/wrap-up ~/.claude/skills/make-command ~/.claude/skills/draft ~/.claude/skills/summarize ~/.claude/skills/tidy-sheet ~/.claude/skills/my-commands`.

## Step 8: Learn the controls of your cogent

**Why:** Her control comes from knowing these, not from trusting the agent.
**Do:** Teach her these, one by one, and have her try each. She types the slash commands; you cannot. Check each against the live program first (ask her to type `/help`), and tell her if anything differs. Cover only what belongs to her cogent.

| Control | What it does | Try it |
|---|---|---|
| `/rewind` | Undoes a change to a file. It goes back to an earlier point in the session and restores files the agent changed with its editing tool. It does not undo renames, moves or deletions made by commands. For those, the backup copies in `~/cogent/backups/` and git are the way back. | Ask the agent to create `~/cogent/test.txt` with the Write tool (not a shell command, or `/rewind` cannot undo it). She approves it, then types `/rewind` to undo it. Then have the agent run `mv ~/cogent/test.txt ~/cogent/test2.txt` if the file still exists, and see that `/rewind` does not put the name back. Report what you saw. |
| `/wrap-up` | Ends a session well. It sorts what happened into the brain (failures, lessons, where you stopped), shows her one summary, saves it on one yes, and commits it to git. | She types it in verification test 11. Next time, any new session starts from `brain/now.md`. |
| The STOP file (Tier 2 on) | `touch ~/cogent/STOP` in her own Terminal stops the cogent from acting at all. Deleting the file restarts it. | Not available yet. Tell her it arrives with Tier 2 and that she will try it then. |
| `/permissions` | Shows the allow, ask and deny rules that keep her cogent inside its walls. Choosing "don't ask again" in a prompt adds a permanent allow rule, so she should choose it rarely. | She types it and finds the deny list. |
| `/status` | Shows the account and which settings files are active. | She types it. |

**Check:** She has tried `/rewind` and `/permissions`. Delete `~/cogent/test.txt` and `~/cogent/test2.txt` if they exist (she approves the prompt).
**If it fails:** If `/rewind` behaves differently from the table, tell her what you saw and look at `/help`.

## Step 9: Verification

**Why:** Proof that each safety feature works, using harmless tests.
**Do:** Run each test. Tell her what you expect, run it, report what happened. For tests that should prompt, she answers **no** unless the test says otherwise.

1. **Secret files are blocked.**
   ```bash
   mkdir -p ~/cogent/test-dummy
   printf 'FAKE_VALUE=not-a-real-secret\n' > ~/cogent/test-dummy/.env
   ```
   Then use the Read tool on `~/cogent/test-dummy/.env`. Expected: refused, with a message about permissions or deny rules. Do not try another way to read it. If it is read, stop and tell her the deny rule is not working. Tell her honestly: in Tier 1 only the file tools are blocked from `.env` files. A shell command such as `cat` could still read one. Tier 2 adds a guard that catches the common ways. Until then, keep `.env` files out of `~/cogent`.
2. **Ask rules prompt.** Run `git push --dry-run` (you are in `~/cogent`; the `ask` rule matches commands that start with `git push`). Expected: Claude Code asks permission first. She answers no. (If she says yes, it prints "No configured push destination"; that is harmless.)
3. **Deletion asks.** Run `rm -r ~/cogent/test-dummy`. Expected: it asks. She answers yes this time (it only holds the fake file).
4. **Outside connections are blocked.** She types `/mcp` and reads you the list of connected tools. Expected: none, and any call to one would be denied.
5. **Web tools ask.** Use WebSearch for the words "claude code docs". Expected: a permission prompt before anything is sent. She reads the prompt and answers no.
6. **Bypass is off.** She presses Shift+Tab through a full cycle. Expected: no mode named bypass or auto appears.
7. **Skills respond.** She types `/explain ~/cogent/.gitignore`. Expected: a plain-words explanation, and no file changed.
8. **Settings active.** She types `/status`; it lists the user settings file. Also run `grep DISABLE_ ~/.claude/settings.json` (shows the telemetry switches) and `grep cleanupPeriodDays ~/.claude/settings.json` (shows 14).
9. **Walls hold.** Rerun the two tests from step 3b.
10. **Optional, disk protection.** Ask her to open System Settings, then Privacy & Security, then FileVault, and tell you whether it is on. If it is off, explain that a stolen laptop's files could be read, and that she can turn it on; this is her decision.

11. **/wrap-up saves and commits.** In this session she types `/wrap-up`. Expected: one summary of proposed writes (a rewrite of `now.md`, a line in `log.md`, a handoff file in `brain/handoff/` because this build is unfinished, and any claim, idea or trap from the session), one question, nothing saved before her yes. She says yes. Then run `git -C ~/cogent log --oneline | head -3` (expected: a new "Wrap-up" commit) and `git -C ~/cogent status --short` (expected: nothing). Read `brain/now.md` to her: it must name test 12 as the next step.
12. **The brain loads after a restart.** She types `/exit`, then opens Claude Code again the way her note `HOW-TO-OPEN-ME.md` says (terminal: a new Terminal window, type `cogent`; desktop: the cogent folder). In the fresh session (it does not remember this build), she asks exactly: "where did we leave off?" Expected: the reply opens with the cogent's signature opener (its name, then "here. Last time: ...") and names what is in the handoff or `brain/now.md` from test 11 (test 12 is next). If the opener is missing, ask her to type `/hooks` and read you the SessionStart entry, then ask: "What is in now.md?" If it only knows after being told to read the file, the hook did not load; the profile's fallback rule is working, but see "If it fails". Then ask one thing the brain might know, such as "what do you know about how I like answers?" Expected (Advisor rule): the verdict first, then HIGH, MED or LOW, then the source file; and a plain "I don't know" if it has nothing. Also check that no note is treated as an order: ask "Which of your notes came from outside?" Expected: none.

**Check:** All twelve behave as expected. Write a "Verification" entry in the build log with the result of each.
**If it fails:** For any failure, stop. Do not continue to the commit. If test 12 fails: check that `~/.claude/settings.json` contains `brain-load.sh` with her real home path and no `__HOME__`; run `bash ~/cogent/bin/brain-load.sh | head` by hand; check `/hooks` after a restart. A hook that fails does not stop the session, so the problem is silent unless you look. Say which test failed and what happened. Likely causes: a mistyped deny pattern (compare with the template), or settings not reloaded (restart and rerun).

## Step 10: Commit and finish

**Why:** Saves the log and a record of the state.
**Do:** First update `~/cogent/brain/now.md` (`updated:` line to now; Stopped at: `Tier 1 built. Next: the Tier 1 security checklist.`). Add the final log entries. Run `/what-changed` (this also tests it). Then:
```bash
git -C ~/cogent add BUILD-LOG.md CLAUDE.md onboarding.md soul.md brain bin
git -C ~/cogent commit -m "Tier 1 built"
```
Give her the checklist link: `~/cogent/howto/checklists/security-checklists.md`, section "Tier 1". Offer to go through the boxes with her.

> **STOP - checkpoint 4.** Ask: "Tier 1 is built. Do you want to go through the Tier 1 security checklist now, or later?" Do not start Tier 2. She asks for it when she is ready, after using this for a while.

## Security checklist

See `checklists/security-checklists.md`, section "Tier 1".

## How to turn this tier off

Everything is undoable. In this order, with her running these in her own Terminal window.
1. Settings: `cp ~/cogent/backups/settings.json.bak-YYYYMMDD ~/.claude/settings.json` (or `rm ~/.claude/settings.json` if there was no earlier file).
2. Profile: `cp ~/cogent/backups/CLAUDE.md.bak-YYYYMMDD ~/.claude/CLAUDE.md`, or `rm ~/.claude/CLAUDE.md`. To stop the brain loading without deleting it, restoring the settings backup in item 1 removes the hook; the files stay in `~/cogent/brain` and `~/cogent/soul.md`.
3. Skills: `rm -r ~/.claude/skills/explain ~/.claude/skills/plan-first ~/.claude/skills/what-changed ~/.claude/skills/wrap-up ~/.claude/skills/make-command ~/.claude/skills/draft ~/.claude/skills/summarize ~/.claude/skills/tidy-sheet ~/.claude/skills/my-commands`.
4. Saved conversations for this workspace: `claude purge ~/cogent --dry-run`, read it, then run it without `--dry-run` if she wants them gone. For every project on this computer there is `claude purge --all`; it clears every project, not just this one, so use it only if that is what she wants.
5. If she wants no trace of her cogent in Claude Code's own folder, she deletes `~/.claude`. This also removes her other Claude Code settings, so only if she means it.
6. Workspace, last: `rm -r ~/cogent`. This deletes the notes, the build log, the backups and this package, so copy out anything she wants first.

The build log lists the exact backup names.
