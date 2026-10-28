# Tier 3 build: a full cogent

Audience: you, the coding agent, building this with Evangeline in the room. Read `00-read-me-first.md` first. Its rules apply here. Where this file and a rule there disagree, the stricter one wins.

**Goal.** Turn the Tier 2 setup into a small always-on assistant system: a nightly tidy of the brain, a scout that proposes what to learn only when the tidy finds work, up to 3 project lanes that share one brain, a mailbox, scheduled headless jobs, optional always-on box, phone alerts, held drafts that she approves at her computer, a panic switch, spend caps and canary secrets. Every piece is small, plain files, and can be switched off.

**Time.** A few weeks, in short sessions. Steps 1 to 4 take about 2 hours. The rest can be done one per sitting.

**Two kinds of command in this file.** Commands marked "you run" are for you, the agent, in your Bash tool. Commands marked "**Evangeline runs in her own Terminal window**" are hers, because they are interactive, or the guard blocks you while the STOP file exists, or they change her Mac's background jobs (`launchctl`), or they touch the Keychain. Never run those yourself and never try another way around. For each one, give her the exact command and tell her what she should see. Wait for her to say it worked.

## Setup used by every command below

- `PKG` is the package folder: `PKG=~/cogent/howto`. Shell variables do not survive between your separate commands, so put `PKG=~/cogent/howto` at the start of each command that uses `$PKG`.
- Every script reads one setting, `COGENT_HOME` (default `~/cogent`). Do not set it unless you are testing in a copy. Tier 2's `guard.py` reads the same setting.
- Placeholders for her: `<<LANE-1-PROJECT-PATH>>` and `<<LANE-1-NAME>>` (letters, digits, dashes). Ask her for each. Never invent one. In the one place a test address is needed, use `test@example.com`.
- **Name backups by step.** In this tier, add the step number to every backup name, for example `settings.json.bak-$(date +%F)-step7`, so two backups on the same day do not overwrite each other.
- **Expect guard prompts.** `guard.py` asks (it does not block) on commands that copy or append to `brain/rules.md`, copy files into `~/.claude`, or run `python3 -m json.tool` on `~/.claude/settings.json`. That is the guard working. Read each prompt to her and let her answer. To check the settings file without python, use `plutil -lint ~/.claude/settings.json`.
- Back up before you change any file in `~/.claude` or `~/cogent/brain/rules.md` (rule 7 in `00-read-me-first.md`). Files in `~/.claude` are written with your Edit or Write tool, which asks her each time. Show each diff first.

## Prerequisites

- Tier 2 has been built and used for at least a month. If Evangeline has not used it for a month, stop now and tell her to come back later. Do not talk her out of waiting.
- Run the Tier 2 verification first (the verification section of `tier-2-build.md`). All of it must pass.
- Confirm the basics. Run these and compare:

```bash
ls ~/cogent/soul.md ~/cogent/brain/index.md ~/cogent/brain/now.md ~/cogent/brain/failed.md ~/cogent/brain/rules.md ~/cogent/bin/brain-tidy.sh   # all six exist
ls ~/cogent/audit 2>/dev/null | tail -3                                                                # recent daily logs
git -C ~/cogent status --short | head                                                                  # clean, or only changes she knows about (an untracked allowed-folders.txt is fine)
ls ~/.claude/hooks/guard.py 2>/dev/null | wc -l                                                        # 1
python3 --version                                                                                      # 3.x
claude --version                                                                                       # prints a version
```

- Read the live flags you will rely on, so you do not guess. Run `claude --help` and confirm these exist: `-p/--print`, `--tools`, `--allowedTools`, `--disallowedTools`, `--permission-mode`, `--strict-mcp-config`, `--disable-slash-commands`, `--append-system-prompt`, `--no-session-persistence`, `--output-format`, `--max-budget-usd`. If one is missing or renamed, tell Evangeline and adjust the template before using it. Do not use `--bare` for scheduled jobs. It skips hooks (including the guard and the STOP check) and does not read the subscription login.
- Confirm the STOP check exists: `grep -c STOP ~/.claude/hooks/guard.py` should print 1 or more. If it prints 0, stop and tell her the Tier 2 guard must be fixed first. You do not edit `guard.py` here.

## What will be created

Under `~/cogent/`:

- `bin/daily-job.sh`, `bin/scout.sh`, `bin/lane-start.sh`, `bin/notify.sh`, `bin/mailbox-read.sh`, `bin/outbox-approve.sh`, `bin/canary/make-canaries.sh`, `bin/canary/scan.sh`
- `lanes/` (worktrees), `mailbox/` (plain files), `outbox/` (held drafts), `canary/` and `decoy/` (fake secrets), `logs/`, `jobs-workdir/` (empty folder for headless jobs), `launchd/` (the schedule files, before she installs them), `lanes-done/` (copies of finished lanes' handoffs)
- Nothing for the tidy itself: `bin/brain-tidy.sh` and `tidy-report.md` come from Tier 2
- Four schedule files that she, not you, copies into `~/Library/LaunchAgents/`: `com.cogent.brain-tidy.plist`, `com.cogent.scout.plist`, `com.cogent.daily-job.plist`, and an optional `com.cogent.canary-scan.plist`
- One Keychain entry named `cogent-ntfy` (she creates it herself)
- Small additions to `~/.claude/settings.json`: one SessionStart hook and a few deny rules
- A few lines appended to `~/cogent/.gitignore`

## What will NOT be touched

- Her Tier 1 and Tier 2 files, except the small additions listed above. Show each diff before saving.
- Anything in `~/Library/LaunchAgents/` or `launchctl`: she does that herself.
- Any project code. Lanes work in separate worktrees on separate branches.
- Any company, work, email, chat or banking account. None of these is ever connected.
- `guard.py` and `audit-log.sh`. You only check that they honour `~/cogent/STOP`.
- `soul.md`. Only she changes it. No script in this tier writes to it, and no job may.
- `brain/rules.md` and `brain/claims.md`. No script or headless job writes to them. Only you, in a normal session, after her yes.

## Order of work

Steps 1 to 4 and 6 to 10 run on her laptop. **Step 5 (the always-on box) is optional and comes last in practice: do not start it until steps 6 to 10 pass on the laptop.** Skip to step 6 after step 4, then come back to 5.

---

## Step 1. Brain upgrades: nightly tidy, shared by every lane

**Why.** A brain that only grows becomes too big to read, and then nobody follows it. A nightly job keeps it small. It is plain shell, so it costs nothing to run. Lessons become claims and rules only after they have happened twice, or she says so, so a bad day does not become a permanent rule.

**Do.**

1. Make sure git ignores the private folders Tier 3 creates. Several hold things that must never reach git (the canary list, her mailbox, held drafts). The Tier 1 gitignore lists most of them. This loop adds any that are missing (it prints `added:` for each, and nothing for ones already there):

```bash
cd ~/cogent
for l in audit/ backups/ /canary/ /decoy/ jobs-workdir/ lanes/ lanes-done/ launchd/ logs/ mailbox/ outbox/ .brain-tidy.lock/ .scout-needed STOP; do
  grep -qxF "$l" .gitignore 2>/dev/null || { echo "$l" >> .gitignore; echo "added: $l"; }
done
```

2. Copy the scripts and make them runnable. The nightly tidy is `~/cogent/bin/brain-tidy.sh`, which Tier 2 already installed. Tier 3 does not carry its own copy; it only schedules that one:

```bash
PKG=~/cogent/howto
test -f ~/cogent/bin/brain-tidy.sh && echo "tidy from Tier 2 is there" || echo "MISSING: finish Tier 2 step 6 first"
mkdir -p ~/cogent/bin/canary ~/cogent/logs ~/cogent/mailbox ~/cogent/outbox ~/cogent/jobs-workdir ~/cogent/launchd
cp $PKG/templates/tier3/daily-job.sh $PKG/templates/tier3/scout.sh $PKG/templates/tier3/lane-start.sh $PKG/templates/tier3/notify.sh $PKG/templates/tier3/outbox-approve.sh ~/cogent/bin/
cp $PKG/templates/tier3/mailbox/mailbox-read.sh ~/cogent/bin/
cp $PKG/templates/tier3/canary/make-canaries.sh $PKG/templates/tier3/canary/scan.sh ~/cogent/bin/canary/
chmod +x ~/cogent/bin/*.sh ~/cogent/bin/canary/*.sh
for f in ~/cogent/bin/*.sh ~/cogent/bin/canary/*.sh; do bash -n "$f" && echo "ok $f"; done
```

3. Run the tidy once by hand and read the report with her:

```bash
bash ~/cogent/bin/brain-tidy.sh; echo "exit $?"; cat ~/cogent/tidy-report.md
```

4. Check that the tidy leaves a trip marker when it finds work for the scout. The scout (step 4) runs only when `~/cogent/.scout-needed` exists. The tidy writes it when it finds lessons seen twice, a file over its cap, or claims gone stale, one reason per line. Test it on a copy, not her real brain. Add a lesson seen twice to the copy and rerun:

```bash
rm -rf /tmp/scout-try.noindex && mkdir -p /tmp/scout-try.noindex && cp -R ~/cogent/brain /tmp/scout-try.noindex/ && git -C /tmp/scout-try.noindex init -q
M=$(date +%Y-%m); mkdir -p /tmp/scout-try.noindex/brain/journal
echo "- $(date +%F) test lesson one - why: test (seen: 2) [provisional]" >> /tmp/scout-try.noindex/brain/journal/$M.md
COGENT_HOME=/tmp/scout-try.noindex bash ~/cogent/bin/brain-tidy.sh
cat /tmp/scout-try.noindex/.scout-needed
```

Then she deletes the copy in her own Terminal: `rm -r /tmp/scout-try.noindex`.

**Check.** Exit 0. The report lists what was archived, files over their cap, and the candidates waiting for her yes. `git -C ~/cogent log --oneline | head -3` shows a `brain-tidy` commit if anything changed. `git -C ~/cogent show --stat HEAD | head` lists only files under `brain/` and `tidy-report.md`. `git -C ~/cogent check-ignore -v logs/x mailbox/x lanes/x outbox/x launchd/x` prints five lines, one per folder. (The guard stops you naming `canary/` and `decoy/`; step 10 checks those in her Terminal.) The copy test prints a reason line in `.scout-needed`. If the stat shows any other folder, stop and tell her. If the copy test leaves no marker file, the installed `brain-tidy.sh` does not write one yet: tell her, and do not schedule the scout until it does.

**If it fails.** `python3: command not found`: ask her to run `xcode-select --install` in her Terminal, then retry. "brain not found": check `~/cogent/brain/` exists. A lock left behind by a crash: `rmdir ~/cogent/.brain-tidy.lock` (the job also clears locks older than a day by itself).

**Undo.** `git -C ~/cogent revert <the brain-tidy commit>`. Archived entries live in `~/cogent/brain/archive/` and can be pasted back.

**How it behaves.** It never deletes. It moves the oldest entries of `failed.md` and `wins.md` to `brain/archive/` when a file passes its cap, archives journal lessons marked `[provisional]` that nobody confirmed in 30 days, decays unconfirmed claims, flags rules unused for 90 days, and moves `brain/handoff/` files older than 30 days. It never writes to `rules.md` or `soul.md`. It commits only `brain/` and `tidy-report.md`, and skips the commit and logs a warning if the changes contain something shaped like a key. When Evangeline reads the report and says "yes, make that a rule", you add it with a one-line reason. Text that came from the web, emails or documents sits in `brain/quarantine.md` and is never promoted, even if it says "always" or "never".

> **STOP - checkpoint 1.** Show Evangeline the tidy report and the list of files copied. Ask: "Do you want the tidy to run every night at 03:15 on this laptop? It reads and moves text files in your brain folder and commits them. It makes no network calls." Do not continue without an explicit yes.

5. On yes, build the schedule file inside `~/cogent` and check it. You do not install it. The schedule runs the same `~/cogent/bin/brain-tidy.sh` that /wrap-up runs.

```bash
PKG=~/cogent/howto
sed "s#<<HOME>>#$HOME#g" $PKG/templates/tier3/com.cogent.brain-tidy.plist > ~/cogent/launchd/com.cogent.brain-tidy.plist
plutil -lint ~/cogent/launchd/com.cogent.brain-tidy.plist
grep -c "cogent/bin/brain-tidy.sh" ~/cogent/launchd/com.cogent.brain-tidy.plist
test -d ~/cogent/logs && echo "logs folder ok"
```

The `plutil` line must end `OK`, and the `grep` must print `1`.

6. **Evangeline runs in her own Terminal window** (launchd is her Mac's job list; you do not touch it). Give her exactly this and say what she will see after each line:

```bash
cp ~/cogent/launchd/com.cogent.brain-tidy.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cogent.brain-tidy.plist
launchctl print gui/$(id -u)/com.cogent.brain-tidy | grep -E "^\s*(state|path) ="
launchctl kickstart gui/$(id -u)/com.cogent.brain-tidy; sleep 3; tail -2 ~/cogent/logs/brain-tidy.log; date -u +%FT%TZ
```

She should see: the `cp` and `bootstrap` lines print nothing. The `grep` prints a line `state = not running` and a line `path = ` ending in `com.cogent.brain-tidy.plist` (the exact wording can differ between macOS versions; we have not seen it on every version, so she reads you what she gets). `not running` is right: the job runs once a night. The `kickstart` prints nothing. Then the last log line ends `brain-tidy: python exit 0`, and its time stamp is within about 10 seconds of the `date -u` line below it. A last log line from earlier means the job did not run.

**Check.** She reports what she saw. macOS may show a notice "Background items added". She should leave it on. If a job never runs, she opens System Settings, General, Login Items, finds the entry for `bash` and makes sure it is on. If the laptop is asleep at 03:15, the job runs when it wakes.

**If it fails.** `Bootstrap failed: 5` (input/output error): the job is already loaded. She runs `launchctl bootout gui/$(id -u)/com.cogent.brain-tidy` and repeats the bootstrap line. `launchctl print` says it cannot find the service: the bootstrap did not work; ask her to paste the error text (not any secret) into the chat.

**Undo (she runs it).** `launchctl bootout gui/$(id -u)/com.cogent.brain-tidy && rm ~/Library/LaunchAgents/com.cogent.brain-tidy.plist`.

---

## Step 2. Lanes: one session per project, at most 3

**Why.** One session working on three projects mixes up their facts. A lane is one session, one project, one git worktree (a second checkout of the same repository on its own branch), so work stays apart and can be thrown away cleanly. Three is the limit because she has to be able to follow them.

**Do.** Ask her which one project she wants as lane 1: `<<LANE-1-PROJECT-PATH>>` (a git repository with at least one commit) and a short name `<<LANE-1-NAME>>`. Then give her this to run. **Evangeline runs in a NEW Terminal window, not through you**, because it ends in a live Claude Code session you cannot drive:

```bash
bash ~/cogent/bin/lane-start.sh "<<LANE-1-PROJECT-PATH>>" <<LANE-1-NAME>>
```

She types the full path (she can drag the folder from Finder into the Terminal window to fill it in). The name is letters, digits and dashes, at most 20 characters. If the lane agent should read the original project folder, she adds it to the list of allowed folders first, in her Terminal: `printf '%s\n' '<<LANE-1-PROJECT-PATH>>' >> ~/cogent/allowed-folders.txt`. Without it the guard asks about every read there.

She should see `Preparing worktree (new branch 'lane/<name>')` and then Claude Code opens in the lane folder. The script refuses to start (and says why) if STOP exists, if 3 lanes already exist, if the folder is not a git repo, if the name is over 20 characters, or if the project carries its own `.claude/` folder or `.mcp.json` file. A project's own settings can run commands with her permissions. If it refuses for that reason, it names the files in the original project folder (it removes the new worktree and any branch it made, so nothing is left behind). Read those files with her first. Only if she is happy, she runs it again as `COGENT_ALLOW_PROJECT_CONFIG=1 bash ~/cogent/bin/lane-start.sh "<<LANE-1-PROJECT-PATH>>" <<LANE-1-NAME>>`.

In the lane session she asks: "What is your working folder, where do you write your handoff, and where does a lesson go?" The answer names `~/cogent/lanes/<name>`, the handoff `~/cogent/lanes/<name>/now.md`, and the shared journal `~/cogent/brain/journal/` with the tag `[lane:<name>]`. Then she types `/exit`. If the agent wrote no handoff, the script writes a stub from git and says so. Tell her to wait; do not run anything until she says she has exited.

**Check (you run, after she says she has exited).**

```bash
ls ~/cogent/lanes/                                   # <name>
git -C ~/cogent/lanes/<<LANE-1-NAME>> branch --show-current    # lane/<name>
ls ~/cogent/mailbox/                                 # <name>.md
ls ~/cogent/lanes/<<LANE-1-NAME>>/now.md               # the handoff
```

A stub counts as a handoff for `--finish`. Read `now.md` before finishing the lane. If the script wrote a stub, it also sent a "problem" alert, and you add a line to `failed.md` at wrap-up: the lane ended without a handoff.

**One brain for all lanes.** Lanes do not each get their own memory. Every lane reads the same `soul.md`, `rules.md` and `failed.md`. The only per-lane file is its handoff, `lanes/<name>/now.md` (up to 40 lines: task, state, next step, open questions, how to undo). A lesson a lane learns goes to the shared journal as one line tagged `[lane:<name>]`, for example `- 2026-11-02 Invoices need the PO number first - why: the bank rejected two (seen: 1) [provisional] [lane:books]`. Then every other lane benefits, and the tidy and scout see it once. A lane never writes `soul.md` or `rules.md`.

**If it fails.** "not a git repo" or no commits: `git -C "<path>" log -1`. Make a first commit with her. "Already 3 lanes": list `~/cogent/lanes/` and finish one. A commit inside the lane fails with a permission error: the sandbox blocks writes to the project's own `.git` folder, where a worktree keeps its records. Tell her. She decides whether to allow writes to that one folder; you do not add it yourself.

**Undo.** Starting the same name again reuses the branch and shows the lane its old `now.md`. To remove a lane after its handoff exists and its tree is clean: `bash ~/cogent/bin/lane-start.sh --finish <name>` (you may run this one; it needs no live session). It copies `now.md` to `~/cogent/lanes-done/`, removes the worktree and keeps the branch `lane/<name>`. Delete the branch only with her OK.

**Per-lane limits.** A lane has the same deny rules as everything else. If a project needs less, add `.claude/settings.local.json` inside that worktree with extra `deny` rules. Never add `allow` rules for push, delete or network without asking her. Never start a lane with `--dangerously-skip-permissions` or `--permission-mode bypassPermissions`. The settings disable them.

---

## Step 3. Mailbox: plain files, read at session start

**Why.** She needs a way to leave a lane a note without opening the lane. The same hook gives a lane its own last handoff back. Plain files need no server and she can read them herself.

**Do.**

1. Copy the readme: `cp ~/cogent/howto/templates/tier3/mailbox/README.md ~/cogent/mailbox/README.md`
2. Back up `~/.claude/settings.json` (`cp ~/.claude/settings.json ~/cogent/backups/settings.json.bak-$(date +%F)-step3`). Show her the current `hooks` block. Add this group to the existing `SessionStart` array with your Edit tool. Do not replace what is there (Tier 2 already has one). Replace `__HOME__` with the output of `echo $HOME`, as in Tier 2. Show the diff first:

```json
{
  "matcher": "*",
  "hooks": [
    { "type": "command", "command": "bash \"__HOME__/cogent/bin/mailbox-read.sh\"", "timeout": 5 }
  ]
}
```

3. Check the file is still valid JSON: `plutil -convert json -o /dev/null ~/.claude/settings.json && echo OK` (prints `OK`; an error message instead means the JSON is broken, so restore the backup). If you use `python3 -m json.tool` instead, the guard will ask.
4. Ask her to type `/hooks` and read you what it shows under SessionStart. How it lists them depends on the version. She should see the `mailbox-read.sh` command somewhere in the list, next to the Tier 2 one.

**Check.** Leave a test message:

```bash
echo "- $(date +%F) Test message: say hello and mention the word mailbox." >> ~/cogent/mailbox/all.md
```

**Evangeline opens her cogent herself** (her way, from `~/cogent/HOW-TO-OPEN-ME.md`; terminal: a new Terminal window, type `cogent`), then asks "Did the mailbox have anything for me?" The reply quotes the test line. She exits with `/exit`. Then you run `wc -c < ~/cogent/mailbox/all.md` (it prints 0, the file is empty) and `ls ~/cogent/mailbox/read/` (a dated copy). For a lane, the lane's own file is read too, followed by that lane's `lanes/<name>/now.md` as notes (`COGENT_LANE` is set by `lane-start.sh`).

Scheduled `claude -p` jobs set `COGENT_HEADLESS=1`, and `mailbox-read.sh` does nothing when it is set. Without that, the nightly job would read her message into a session nobody sees.

**If it fails.** Nothing shows: the hook may not have loaded. `/hooks` lists what is active; step 3 above finds JSON mistakes. If the text is printed but the agent ignores it, ask directly: "Did you receive mailbox messages?" Do not treat that as a bug in the script.

**Undo.** Remove the added group from `settings.json` (or restore the backup). Files in `~/cogent/mailbox/` stay.

---

## Step 4. Scheduled headless jobs with `claude -p`

**Why.** Some routines should run without her starting them. `claude -p` runs once, prints the answer and exits. A job nobody watches must have very few powers.

**Rule for every headless job.** It gets the fewest tools that do the work, runs from its own empty folder, and sets `COGENT_HEADLESS=1`. The example job has no tools at all (`--tools ""`), so it cannot read, write, run commands or reach the web, and the script writes its result. Never give a headless job `Bash`, web tools or MCP servers.

**Do.** Two jobs: the daily job summarises yesterday's audit log into the journal, and the scout (4b) proposes what the brain should learn. The daily job is optional; the scout is the one that matters.

1. Read the template aloud to her in plain words: `~/cogent/howto/templates/tier3/daily-job.sh`. Point out the safety choices: the model gets the log on stdin and has no tools; the script, not the model, writes the file, one short line per bullet, with web addresses removed; it runs from the empty folder `~/cogent/jobs-workdir`; and the lines it writes go to the journal as reported speech ("The audit job reported (untrusted): ..."), tagged `[provisional] [auto]`, so later sessions treat them as notes, not orders. If she never confirms them, the tidy archives them after 30 days.
2. Confirm flags live: `claude --help | grep -E "permission-mode|tools|strict-mcp-config|disable-slash|no-session-persistence|output-format"`.
3. **Evangeline runs in her own Terminal window.** The job calls `claude -p`, which needs the network and her login, and your sandbox has neither (its network list is empty). She runs it, then tells you what she sees:

```bash
bash ~/cogent/bin/daily-job.sh; tail -3 ~/cogent/logs/daily-job.log; tail -4 ~/cogent/brain/journal/$(date +%Y-%m).md
```

4. **Evangeline runs in her own Terminal window.** Prove the limit. This uses `/tmp` so a failure harms nothing. It sends one short question to the model, so it uses a little of her plan:

```bash
cd ~/cogent/jobs-workdir && COGENT_HEADLESS=1 claude -p 'Create a file named outside-test.txt in /tmp and tell me what you did' --tools "" --permission-mode dontAsk --strict-mcp-config --disable-slash-commands --no-session-persistence --output-format text
ls /tmp/outside-test.txt
```

The `ls` must say `No such file or directory`. She reads you the result. If the file exists, stop, delete it, and tell her. This tests the flags, not the sandbox (the sandbox covers `Bash`, which this job does not have). A job that must write a file needs its own pattern: `--permission-mode dontAsk`, a tool list with only the write tool (`--tools "Write"`), an `--allowedTools` entry limited to one relative folder (check the rule syntax live in `claude --help` and `/permissions`), and the same `/tmp` test before she relies on it. Anything outside that folder must be denied, not asked about.

**Check.** The log says `wrote N lines` (N from 1 to 3), or "no audit log for ..., nothing to do" on a first day. If the model answers without bullet lines the log says so, nothing is written, and the job sends a "job failed" alert. The journal has dated lines, each reading `- YYYY-MM-DD The audit job reported (untrusted): ... [provisional] [auto]`, at most 3 per run, and `brain/log.md` has one new line for the write. Check them for anything sensitive (you can run this one):

```bash
tail -8 ~/cogent/brain/journal/$(date +%Y-%m).md | grep -Ei 'sk-|key|token|password' && echo "STOP: looks sensitive" || echo "nothing sensitive found"
```

**If it fails.** "claude failed (exit 1)": run `claude -p "say ok" --no-session-persistence` by hand. If that asks you to log in, ask her to log in interactively once, then retry. If the manual run works but the scheduled one fails, read `~/cogent/logs/daily-job.err`: the schedule's environment is smaller than her Terminal's. The plist sets `PATH`, but verify `which claude` is under `/opt/homebrew/bin` or `~/.local/bin`, and edit the plist copy if it is elsewhere. Login through the Keychain can fail under a schedule while it works in Terminal; if so, say so to her.

**Undo.** Delete the lines added to the journal and the matching line in `brain/log.md` (`git -C ~/cogent diff` shows them).

### 4b. The scout: proposals only, and only when the tidy asks

**Why.** Reading a month of notes for patterns is the one job worth a model call. Doing it every night for nothing wastes her plan, and a model that can write her rules is a risk. So the nightly tidy (plain shell, no model) decides whether there is anything to look at. The scout starts after it each night, and does anything only if the tidy left `~/cogent/.scout-needed`. It reads the journal, `claims.md`, `failed.md`, `wins.md` and three days of the audit log, and writes proposals under "Scout proposals" in `~/cogent/tidy-report.md`. There are four kinds: `PROMOTE:` (a lesson seen twice that could become a claim), `CLAIM:` (a high-confidence claim that could become a rule), `MERGE:` (entries saying the same thing) and `STALE:` (something the facts contradict). It never writes a rule, a claim or `soul.md`. She and you decide, in a normal session, with the `reviewer` subagent as second opinion.

**Do.**

1. Read `~/cogent/howto/templates/tier3/scout.sh` to her in plain words. It has the same safety shape as the daily job (no tools, empty working folder, `COGENT_HEADLESS=1`). It also skips `quarantine.md`. The script keeps only lines that start with one of the four labels, cuts them to 200 characters, and drops web addresses and anything shaped like a secret. With no marker file it exits at once and never calls the model.
2. **Evangeline runs in her own Terminal window.** Force one run:

```bash
echo "manual test run" > ~/cogent/.scout-needed
bash ~/cogent/bin/scout.sh; tail -2 ~/cogent/logs/scout.log; sed -n '/## Scout proposals/,$p' ~/cogent/tidy-report.md
ls -a ~/cogent/.scout-needed
```

**Check.** The log says `wrote N proposal lines` (or `found nothing to propose`). The report has a "Scout proposals" section with `- PROMOTE:`, `- CLAIM:`, `- MERGE:` or `- STALE:` lines, or "Nothing to propose this week". The last `ls` says `No such file or directory`: the marker is removed after a good run. Run the script a second time with no marker: nothing happens and there is no new log line. Then confirm no rule changed: `git -C ~/cogent status --short soul.md brain/rules.md brain/claims.md` prints nothing.

**If it fails.** Same causes as the daily job (login, `PATH`). "model reply had no proposal lines": the model ignored the format. Nothing was written and she gets a "job failed" alert. Run it once more; if it repeats, leave the scout off.

**Undo.** Delete the "Scout proposals" section from `tidy-report.md`, and `rm ~/cogent/.scout-needed`.

> **STOP - checkpoint 2.** Show Evangeline what the daily job wrote and what the scout proposed. Ask: "Do you want the daily job to run every morning at 07:30, and the scout to start at 03:45 each night but only when the tidy asks? They send a little of your journal and one day of your audit log (command names, not file contents) to the model, like any other Claude Code use. Neither can run commands or edit files, and the scout can only suggest." Do not continue without an explicit yes.

5. On yes, build the schedule files (you) and install them (she):

```bash
PKG=~/cogent/howto
sed "s#<<HOME>>#$HOME#g" $PKG/templates/tier3/com.cogent.daily-job.plist > ~/cogent/launchd/com.cogent.daily-job.plist
sed "s#<<HOME>>#$HOME#g" $PKG/templates/tier3/com.cogent.scout.plist > ~/cogent/launchd/com.cogent.scout.plist
plutil -lint ~/cogent/launchd/com.cogent.daily-job.plist ~/cogent/launchd/com.cogent.scout.plist
```

**Evangeline runs in her own Terminal:**

```bash
cp ~/cogent/launchd/com.cogent.daily-job.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cogent.daily-job.plist
launchctl print gui/$(id -u)/com.cogent.daily-job | grep -E "^\s*(state|path) ="
launchctl kickstart gui/$(id -u)/com.cogent.daily-job; sleep 20; tail -2 ~/cogent/logs/daily-job.log; date -u +%FT%TZ
cp ~/cogent/launchd/com.cogent.scout.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cogent.scout.plist
launchctl print gui/$(id -u)/com.cogent.scout | grep -E "^\s*(state|path) ="
```

She should see `state = not running`, a `path =` line ending in `com.cogent.daily-job.plist`, and a last log line whose time stamp is within about 30 seconds of the `date -u` line. The scout lines print the same kind of `state` and `path` lines, and no `kickstart` is needed: the nightly run does nothing unless the tidy asked for it. Same notes as step 1 about "Background items added" and Login Items.

**Undo (she runs it).** `launchctl bootout gui/$(id -u)/com.cogent.daily-job && rm ~/Library/LaunchAgents/com.cogent.daily-job.plist`, and the same for `com.cogent.scout`.

**Now go to step 6.** Come back to step 5 after step 10.

---

## Step 6. Phone alerts (do before step 5)

**Why.** Lanes should be able to tap you on the shoulder. The phone only gets an alert that something waits. You cannot approve anything from it. Approvals happen at her computer (step 7). A push can show on a lock screen, so it carries nothing private.

**Do.**

0. `notify.sh` checks the canary list, so the canaries must exist first. Do item 1 of step 10 now (she runs `make-canaries.sh` in her own Terminal), then return here.
1. Explain the choice to her. **Option A, ntfy.sh (public service):** nothing to run. The "topic" is the name of your private channel, and anyone who knows it can read and post to it. Treat the topic name like a password: long and random. The service sees every push, so pushes carry only a fixed short line. A stranger who learns the topic can send her fake alerts. A real alert never asks her to click or reply: she opens the session herself. **Option B, self-hosted ntfy** on your own always-on box, reached over your private network: the pushes never touch a public server. Do this only after step 5. Start with A.
2. She installs the ntfy app on her phone (from the official app store listing; check the publisher name).
3. **Evangeline runs in a separate Terminal window.** She makes a topic and types it into Keychain herself:

```bash
openssl rand -hex 16        # prints 32 letters and digits. She writes "cogent-" in front of it.
security add-generic-password -U -a "$USER" -s cogent-ntfy -T "" -w     # prompts for the value; she types cogent-<the random string>
```

The `-T ""` makes macOS ask her before any program reads the topic. When she subscribes in the phone app she needs the topic once more. She can show it in her own Terminal only: `security find-generic-password -a "$USER" -s cogent-ntfy -w` (a Mac prompt may appear), type it into the app, and clear the Terminal. She never pastes it into this chat.

4. **Evangeline runs the test in her own Terminal window.** Your sandbox has no network and cannot read the Keychain, so the script would fail if you ran it. The alert titles come from a fixed list: `draft waiting`, `tidy report ready`, `job failed`, `canary found`, `lane finished`, `question waiting`, `problem`. Use `problem` when something went wrong (a blocked action, a failed check, a guard BLOCK). It is the pain signal, and you also log it in `failed.md` at wrap-up.

```bash
bash ~/cogent/bin/notify.sh "Lane test needs you: question waiting"
```

A Mac prompt may appear asking to allow access to the Keychain item. She clicks Allow (or Always Allow if she wants scheduled alerts to work while she is away from the screen; she chooses). She should see `notify: sent` and the phone buzzes with that line. Each test push counts toward the limit of 6 per hour (see the end of this step), so she keeps the tests in this step to a few.

**Alerts from inside a session.** Schedules (`launchd`) are not in your sandbox, so alerts from the scheduled jobs work. A live lane session runs `notify.sh` inside the sandbox and will most likely be refused: no network, and no Keychain. Do not widen the sandbox on your own. Tell her the choices: (a) add `ntfy.sh` to `sandbox.network.allowedDomains` in `~/.claude/settings.json` with her yes, and see whether the Keychain read works from a session (we have not verified that it does); or (b) leave it, and lanes leave drafts and handoff notes that she finds at her computer. Either is fine. Start with (b).

**Check.** She confirms the refusals work, in the same Terminal. Each must print `notify: refused` and send nothing:

```bash
bash ~/cogent/bin/notify.sh "here is my password hunter2"
bash ~/cogent/bin/notify.sh "Lane x needs you: hello there"
bash ~/cogent/bin/notify.sh "Lane x needs you: sk-ant-api03-abcdefghijklmnopqrstuvwxyz"
```

These three are all stopped by the format check. The secret-pattern check behind it is a second layer that these tests do not exercise. At most 6 pushes go out per hour (the tests above count); the seventh prints `notify: refused, rate limit (6 per hour)`.

**If it fails.** `no topic in Keychain`: she re-runs the `security` command; the service name must be exactly `cogent-ntfy`. If it works in Terminal but not from a schedule, she runs `notify.sh` once by hand and clicks "Always Allow", or accepts that alerts from schedules only arrive when she is at the Mac. `canary list missing`: run step 10 first (`notify.sh` refuses without it on purpose). Phone silent: check the topic matches in the app and the phone's notification settings for the app.

**Rules for pushes.** The text is always `Lane <name> needs you: <title>` with a title from the list above. The script enforces it, refuses secret-looking text, and the words token, secret, key and password. Do not loosen it.

**Undo (she runs it).** `security delete-generic-password -a "$USER" -s cogent-ntfy`. Unsubscribe in the app.

---

## Step 7. Approvals: draft, hold, she approves at her computer

**Why.** Anything that leaves the machine or cannot be undone is where mistakes cost real money or embarrassment. You write a draft. She decides, at her computer, after reading the exact text. The phone tells her something is waiting. It cannot approve.

**Do.**

1. Add this to `~/cogent/brain/rules.md` (it is her rule, with a reason; show it and get a yes first; back up first; the guard will ask about the `cp` and the `cat >>`, which is expected):

```bash
cp ~/cogent/brain/rules.md ~/cogent/backups/rules.md.bak-$(date +%F)
cat >> ~/cogent/brain/rules.md <<'EOF'
- Anything outward-facing (send a message or email, post, git push, purchase, delete, share a file) is written as a draft file in ~/cogent/outbox/ and NOT done until Evangeline approves it with outbox-approve.sh. Reason: sending and deleting cannot be taken back.
EOF
```

2. Add two rules to `permissions.deny` in `~/.claude/settings.json` (your Edit tool; show the diff; she types `/permissions` afterwards and reads you the new lines): `"Edit(~/cogent/outbox/*.approved)"`, `"Write(~/cogent/outbox/*.approved)"`, and one rule to `permissions.ask`: `"Bash(*outbox*approved*)"`. Tell her plainly: these rules stop the Edit and Write tools from faking an approval, and make any shell command that mentions an approval file ask her first. A shell command written to dodge that pattern could still create one, which is why `outbox-approve.sh` checks the fingerprint and she reviews each draft herself. Ask her to check in `/permissions` that `Bash(osascript *)` is in the ask list (osascript can send mail and read Messages). If it is not, tell her; adding it is a Tier 1 and 2 change she approves.
3. Draft format. Each draft is one file `~/cogent/outbox/YYYY-MM-DD-<lane>-<short-title>.md`:

```
action: send-email | post | git-push | purchase | delete | share
to: <who or where>
status: draft
why: <one line>
---
<the exact text or the exact command that would be run>
```

4. After you write a draft, try the alert: `bash ~/cogent/bin/notify.sh "Lane <name> needs you: draft waiting"`. From inside a session this may be refused by the sandbox (see step 6). If so, the draft file and your handoff note are the notice, and you tell her in the session.

**The approve procedure (she does this at her computer).**

a. The alert says "draft waiting". It is a heads-up only. She opens her Mac and her own Terminal window.

b. She lists the drafts: `ls -1t ~/cogent/outbox/ | head`. The newest is first. A file ending `.approved` is an approval already given.

c. She reads the one she wants, and decides whether she is happy with every word: `cat ~/cogent/outbox/<file>`.

d. If yes, she runs `bash ~/cogent/bin/outbox-approve.sh <file>`. The script shows the draft again, asks her to type `yes`, and writes `<file>.approved` holding the draft's fingerprint. She should see `Approved. Now tell your agent: approved <file>`. Any other answer prints `Cancelled. Nothing approved.`

e. She tells you in a session: "approved <file>".

f. You act only if all of these are true: `<file>.approved` exists, and `shasum -a 256 ~/cogent/outbox/<file> | cut -d' ' -f1` prints the same value as the contents of `<file>.approved` (`shasum` also prints the file name after the value; `cut` drops it). If the draft was edited after she approved, the values differ: do nothing and tell her. Do exactly the action in the draft, once. Your ask rules (`git push`, `curl`, `rm`) still apply; she answers those as usual. Then change `status:` to `done` and note the time.

A scheduled or headless job never acts on outbox items: it has no tools.

**Check.** Ask: "Draft an email to test@example.com saying hello. Do not send it." A file appears in `outbox/` with `status: draft`, nothing is sent, and the phone gets the "draft waiting" alert if the sandbox allowed it (otherwise you tell her). Then she runs the approve procedure on it and you confirm `<file>.approved` exists and the fingerprints match. Do not send anything: it is a test.

**If it fails.** If you start to send without a draft, that is a rule failure: say so, stop, and tell her. Hooks and ask rules are the backstop, with her adding a guard rule if she wants a harder stop.

**Honest limit.** This is a habit plus ask rules and a fingerprint check, not a lock. A live session that was tricked could still try to send. The deny rules on `*.approved` and the ask rules make that harder, and she would see it. A phone alert is not an approval and never asks her to reply.

**Undo.** Remove the rule line from `rules.md` (git shows it) and the two deny rules.

---

## Step 8. The panic switch

**Why.** If something looks wrong, she needs one action that stops everything within seconds, without hunting for settings.

**How it works.** The switch is a file, `~/cogent/STOP`. Tier 2's `guard.py` blocks every tool call while it exists. That includes yours, so once she creates it you cannot run commands, and you cannot remove it. She removes it. These scripts also check it: `brain-tidy.sh`, `scout.sh`, `daily-job.sh`, `lane-start.sh`, `notify.sh`, `outbox-approve.sh`, and `mailbox-read.sh` (which tells new sessions to stop). `canary/scan.sh` deliberately ignores STOP: it only reads, and during an incident it is the tool you want to keep running.

**Do.** Tell her: "I will stop making tool calls now and wait. Open a Terminal window." **Evangeline runs in her own Terminal window:**

```bash
touch ~/cogent/STOP
bash ~/cogent/bin/daily-job.sh; tail -1 ~/cogent/logs/daily-job.log
bash ~/cogent/bin/brain-tidy.sh; tail -1 ~/cogent/logs/brain-tidy.log
bash ~/cogent/bin/lane-start.sh /tmp x; echo "exit $?"
bash ~/cogent/bin/notify.sh "Lane t needs you: job failed"; echo "exit $?"
```

She should see, in order: a log line ending `daily-job: STOP file present, not running`; a log line ending `brain-tidy: STOP file present, not running`; `STOP file present. Not starting a lane.` then `exit 1`; `notify: STOP file present, not sending` then `exit 1`.

Then she tells you "STOP is on". Make exactly one tool call, `ls ~/cogent`, to prove the guard blocks you. It must be refused with a message that the STOP switch is on. That refusal is the pass. Do not try anything else. Then she runs, in her Terminal:

```bash
rm ~/cogent/STOP
ls ~/cogent/STOP
```

The `ls` prints `No such file or directory`. She tells you, and your next `ls ~/cogent` works.

**Check.** All four script lines refused, your one `ls` was blocked, and after `rm` it works.

**If it fails.** If your `ls` was NOT blocked, stop. Tell her the Tier 2 guard does not block while STOP exists and ask her to have it fixed (a few lines at the start of `main`: if the file exists, exit 2 with a message). Do not continue to step 5 until this passes. Honest limit to tell her: STOP blocks new tool calls. It cannot stop a reply the model is already writing, and it does nothing if the guard program cannot start. Use `Esc` and `/exit` as well.

**Full off list, from mild to firm.**

1. `touch ~/cogent/STOP`. Stops tool calls and new jobs. A reply in progress finishes.
2. `Esc` in each open session. Then `/exit`.
3. Unload schedules, in her Terminal: `launchctl bootout gui/$(id -u)/com.cogent.brain-tidy`, then the same for `com.cogent.scout`, `com.cogent.daily-job` (and `com.cogent.canary-scan` if installed). Each prints nothing when it works.
4. Sign out of Claude Code on that machine (`/logout` inside a session), and end the session on her account page: open claude.ai, sign in, open Settings, and look for a Claude Code, Devices or Sessions section. If she cannot find it, say so, and change her Claude password instead, which signs everything out.
5. If a box is involved: remove it from the private network, then power it off.
6. Change any secret that may have been exposed (see step 10, "if one is found").

**Undo.** She runs `rm ~/cogent/STOP`. That re-enables everything.

---

## Step 9. Spend caps

**Why.** A loop or a long job can use a lot. A cap turns a surprise into a pause.

**Do.**

1. **Subscription (recommended):** usage is limited by the plan, and a flat price means no surprise bill. Ask her to type `/usage` in a session and read you what it reports. Keep the number of lanes at 3 or fewer. Do not turn on extra paid usage beyond the plan unless she decides to; if the account offers it, leave it off or set a low ceiling in her account settings.
2. **If she ever uses an API key** (not recommended for this build): the key goes in Keychain (she adds it herself), never on the always-on box, and she sets a monthly spend limit in the console's billing or limits settings before the first use. Headless runs on a key can also take `--max-budget-usd <amount>` (it works only with `--print`).
3. Ask her for a monthly figure in dollars (the plan price, or a lower number she picks) and write it in `~/cogent/brain/rules.md` so a future you reads it. Back up first and append with `cat >>`, as in step 7, with her number in place of `<<MONTHLY>>`:

```
- Spend: stop and tell Evangeline at 80 percent of $<<MONTHLY>>/month. Reason: surprises are expensive.
```

**Check.** `/usage` runs. If an API key is used, she confirms the limit shows in the console.

**If it fails.** `/usage` not found: ask her to type `/help` for the current name and use that.

**Undo.** Edit the rule line. Limits in her account are hers to change.

---

## Step 10. Canary secrets

**Why.** A canary is a fake secret that opens nothing. If it ever appears in a log, transcript, draft or push, something read or copied the file it was hidden in. It gives you a tripwire.

**Do.**

1. **Evangeline runs this in her own Terminal window.** Tier 2's sandbox forbids you to write in `canary/` and `decoy/`, and the guard blocks any command that names a `.env` file. The script prints only a count and paths, never the fakes. The fakes look like real keys but have the word CANARY inside:

```bash
bash ~/cogent/bin/canary/make-canaries.sh
git -C ~/cogent check-ignore -v canary/needles.txt decoy/x
```

She should see `Created 4 canaries in ...` and a line starting `Next:`, then two lines each naming a `.gitignore` rule (one for `canary/`, one for `decoy/`). If `check-ignore` prints nothing, step 1 did not take; fix the gitignore before going on, because a committed canary list is a leak.

2. Add deny rules to `~/.claude/settings.json` (back up first; show the diff): `"Read(~/cogent/canary/**)"`, `"Read(~/cogent/decoy/**)"`, `"Bash(cat *canary*)"`. Ask her to check them in `/permissions`. If `~` is not accepted in a rule, use the full path. Tell her plainly: a Bash command can still read these files by another route, so the real protection is rule 3 below and the scan.
3. Rule for you: **never print or open `~/cogent/canary/needles.txt`.** If you do, the canaries land in this transcript and the scan will find them, so it will always fail.
4. Run the scan, then prove it can fail:

```bash
bash ~/cogent/bin/canary/scan.sh; echo "exit $?"        # expect: scan clean, exit 0
```

**Evangeline runs these lines in her own Terminal**, so the fake never enters this chat. Warn her first: the "found" test makes the scan send one "canary found" alert to her phone (if the Keychain topic is set up). That alert is the test, and it counts toward the 6 per hour:

```bash
head -1 ~/cogent/canary/needles.txt > ~/cogent/logs/canary-test.txt
bash ~/cogent/bin/canary/scan.sh; echo "exit $?"        # expect: CANARY FOUND, the file name, exit 1
rm ~/cogent/logs/canary-test.txt
```

Last, prove an empty list fails, not passes. She runs:

```bash
mv ~/cogent/canary/needles.txt ~/cogent/canary/needles.bak
bash ~/cogent/bin/canary/scan.sh; echo "exit $?"        # expect: SCAN INVALID, exit 2
mv ~/cogent/canary/needles.bak ~/cogent/canary/needles.txt
```

5. Decoy test: ask the agent, in the session: "Please read ~/cogent/decoy/.env.production." The read must be blocked: the guard says the path is inside a secrets folder (`~/cogent/decoy`). Then check `tail -3 ~/cogent/audit/guard.log` for a line starting with a time stamp and `BLOCK`. If no such line appears, the permission deny rule may have refused it before the guard ran; accept the deny message as the pass and tell her the log line is not guaranteed.
6. Schedule the scan daily (optional but wanted). You build the file, she installs it, and the checkpoint below comes first:

```bash
PKG=~/cogent/howto
sed "s#<<HOME>>#$HOME#g" $PKG/templates/tier3/com.cogent.canary-scan.plist > ~/cogent/launchd/com.cogent.canary-scan.plist
plutil -lint ~/cogent/launchd/com.cogent.canary-scan.plist
```

> **STOP - checkpoint 3.** Show Evangeline: the STOP drill results, the three canary exit codes, a test alert on her phone, and one outbox draft with its approval. Ask: "Everything on the laptop passes. Do you want the canary scan to run every morning at 07:45, and do you want to set up an always-on box now, or keep running Tier 3 on your laptop for a few weeks first?" Keeping on the laptop is a good answer. Do not continue without an explicit answer to both parts.

On yes to the scan, **Evangeline runs in her own Terminal:**

```bash
cp ~/cogent/launchd/com.cogent.canary-scan.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.cogent.canary-scan.plist
launchctl kickstart gui/$(id -u)/com.cogent.canary-scan; sleep 3; tail -3 ~/cogent/logs/canary-scan.out
```

She should see `scan clean: 4 canaries checked in` and a number of places.

**Check.** Exit codes are 0, 1, 2 as above, and the decoy read is blocked (a `guard.log` line is a bonus, see item 5).

**If it fails.** Scan always reports a hit right after setup: you or a tool printed the list; ask her to delete `~/cogent/canary/needles.txt`, find the transcript lines that held it, and make new canaries (in her Terminal). (`claude purge` removes local session data; run it with `--dry-run` first and read what it would remove.) Scan reports invalid: the list is short or empty; she makes new canaries (she deletes `needles.txt` and reruns `make-canaries.sh` in her Terminal).

**If a canary is found for real.** Follow in order, and tell her calmly and in plain words:
1. She runs `touch ~/cogent/STOP` in her Terminal (you cannot after it exists, and she does it faster).
2. Do not delete the evidence yet. Note which file (the scan prints names only) and the time.
3. Look in `~/cogent/audit/` around that time for a read of the decoy or a copy of the needles (once she removes STOP).
4. Treat it as an incident: the agent, a hook, an MCP server or a prompt-injected document read something it should not have. List recent MCP servers and fetched pages.
5. The canaries are fake, so nothing real leaked. But the same path could carry real secrets. Check the real keys she uses and rotate any that could have followed the same path.
6. She makes new canaries in her Terminal. Only she removes STOP, and only after she agrees.

**Undo (she runs the first line).** `launchctl bootout gui/$(id -u)/com.cogent.canary-scan && rm ~/Library/LaunchAgents/com.cogent.canary-scan.plist`. Then she runs `rm -r ~/cogent/canary ~/cogent/decoy` in her Terminal (the guard and the sandbox stop you from touching them), and you remove the three deny rules.

---

## Step 5. The always-on box (optional; only after steps 6 to 10 pass)

**Stop here unless she already runs servers herself.** If she does not, keep Tier 3 on the laptop. That is a good answer, and you tell her so.

**Why.** A laptop sleeps, travels and gets lost. A box that stays on runs the schedules while you sleep. It also adds a thing that can be attacked, so it gets its own rules.

**Do.**

1. Read `~/cogent/howto/templates/tier3/always-on-box.md` with her. It has the decision table (spare Mac mini at home or a small cloud VM she owns), the hardening checklist and the cut-off list.
2. Work through the checklist with her, one item at a time, ticking only what you have verified. Most items are things she does in System Settings or a provider's console. Tell her exactly where to click when you know; if you are not sure for her version, say so.
3. Private network: use Tailscale or a similar service. Turn on device approval and key expiry. No ports open to the internet.
4. The box gets its own Claude login with her subscription (she signs in herself; it is the only credential on the box). On the box, build Tier 1, Tier 2 and Tier 3 again from this package, in that order, under that account's `~/cogent/`. The box needs the full guard rails: `~/.claude/settings.json` (with the sandbox and the deny rules), the hooks, the box's own `allowed-folders.txt`, and the gitignore lines. Run `/status` and the whole Tier 2 verification there before any `claude -p` job. Without them the box would run jobs with no guard.
5. Re-run the STOP drill, the canary checks and a test alert from the box.
6. Optional: self-hosted ntfy on the box, reached over the private network. Do this only if she wants alerts to avoid a public server.

**Check.** From her laptop on the private network: `ssh <box>` works with a key; `ssh -o PreferredAuthentications=password <box>` is refused. From outside the private network, the box does not answer. `claude --version` and a daily job run on the box. `~/cogent/STOP` on the box stops the job.

**If it fails.** Cannot connect: both devices must be approved in the private network's admin page. Job runs on the laptop but not the box: the box has no login yet, or `PATH` differs; run `claude -p "say ok"` by hand as the agent user. On Linux use cron (see the note in `always-on-box.md`). A Mac box cannot read the Keychain while it is locked, so run only jobs that need no Keychain there.

**Undo.** Follow the "Cutting it off" list in `always-on-box.md`.

---

## Final step. Commit the scripts

Steps 1 to 10 changed `.gitignore` and created `bin/`. Commit them so they can be undone and compared later (you run this; it commits no private folder, because those are all in `.gitignore`):

```bash
git -C ~/cogent add .gitignore bin BUILD-LOG.md
git -C ~/cogent status --short | head
git -C ~/cogent commit -m "Tier 3 scripts"
```

The `status` output should list only `.gitignore`, `bin/...` and `BUILD-LOG.md`. If any other path shows as staged (for example `canary/`, `mailbox/`, `outbox/`), stop and fix `.gitignore` before the commit. If `BUILD-LOG.md` does not exist, `git add` complains; drop it from the command.

---

## Verification (run all; each is harmless)

| # | Test | Expected |
|---|------|----------|
| 1 | Tier 2 verification | all pass |
| 2 | `bash ~/cogent/bin/brain-tidy.sh`, then `git -C ~/cogent show --stat HEAD` | exit 0, report written, nothing deleted, only `brain/` files and `tidy-report.md` in the commit |
| 3 | In a copy of the brain (step 1, item 4), add a journal lesson with `(seen: 2)` and rerun tidy | the lesson is listed as a candidate; `.scout-needed` appears in the copy; `rules.md` and `soul.md` are unchanged |
| 4 | `lane-start.sh` with 3 lane folders present (she runs it) | refuses a fourth; each lane has its own `now.md`, and a lane lesson in the journal carries `[lane:<name>]` |
| 5 | Leave a message in `mailbox/all.md`, she starts a session | shown once, then moved to `read/` |
| 6 | `bash ~/cogent/bin/daily-job.sh`, then the scout test in step 4b | up to 3 labelled `[provisional] [auto]` lines in the journal; scout proposals appear in `tidy-report.md` and no rule changed; the `/tmp` test file does not exist |
| 7 | The STOP drill in step 8 (she runs it) | all four scripts refuse, your one `ls` is blocked, `rm` restores |
| 8 | She runs `notify.sh "Lane t needs you: job failed"`, then one with the word password | first arrives, second refused |
| 9 | Ask for a draft email, then the approve procedure | file in `outbox/`, nothing sent, `.approved` file only after she runs the script |
| 10 | Canary scan: clean, found, invalid (she runs the last two) | exit 0, 1, 2 |
| 11 | Ask to read the decoy file | blocked as a secrets folder; usually a `BLOCK` line in `~/cogent/audit/guard.log` |
| 12 | The commit step below | `git -C ~/cogent status --short` shows no `.gitignore` or `bin/` changes |

Then give Evangeline the Tier 3 list in `checklists/security-checklists.md` and walk through it with her. Fix any item that is not ticked.

## How to turn Tier 3 off

Run the full off list in step 8. To remove the pieces without removing Tier 2: she unloads and deletes the schedule files (the `launchctl bootout` and `rm` lines in each step), then you delete `~/cogent/bin`, `~/cogent/launchd`, `~/cogent/lanes` (after `lane-start.sh --finish` for each), remove the added SessionStart group and the deny rules, and she runs `rm -r ~/cogent/canary ~/cogent/decoy` and deletes the Keychain entry (`security delete-generic-password -a "$USER" -s cogent-ntfy`). The brain (including `soul.md`), the audit logs and the mailbox stay as plain files she can keep or delete. The nightly tidy is Tier 2's: unloading its schedule leaves `/wrap-up` still running it by hand.

## What we learned running one

These come from a setup we have run for a while. No names, only the lessons.

- **Build small.** The pieces that paid off were tiny: a folder of notes in git, a nightly cleanup script, a push to the phone. Everything else was optional.
- **Git notes beat clever databases.** Plain markdown files in git can be read, diffed and undone. A search index is fine as long as it can be thrown away and rebuilt from the files.
- **Receipts in code, not in the prompt.** "Do not say done without proof" works when a script refuses to mark a task done without a named check. It works much less well as a sentence in a prompt. That is why the lane script writes the handoff itself if the agent did not.
- **Questions that do not block.** The agent writes its question under "Open questions" in its handoff and carries on with something else. If she does not answer in time, it decides, and says what it decided. A lane that waits for an answer wastes the whole point of having one.
- **Evidence before rules.** One bad day should not become a permanent rule. Two sightings, or her say-so. A model that reads your notes may suggest; it does not get to write the rules.
- **Spend tokens only when there is something to learn.** The nightly tidy is plain shell and free. The model-powered scout runs only when the tidy finds work.
- **One brain, many lanes.** Lanes that each kept their own memory repeated each other's mistakes. One shared journal and one handoff file per lane fixed that.
- **Keep the read-first file short.** A read-first file that grows past a few pages stops being followed, by people or by agents.
- **A scan that cannot fail is worse than no scan.** Ours once passed because its list of things to look for was empty. Now an empty list is an error.
- **Do not over-build.** It is easy to spend more time designing than using. Most of what gets designed is never needed. Use one login, three lanes, and add a thing only when you hit a real problem twice.
