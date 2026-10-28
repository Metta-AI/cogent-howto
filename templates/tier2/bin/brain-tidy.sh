#!/bin/bash
# brain-tidy.sh - tidy ~/cogent/brain/. Plain files only. No model calls. Run by /wrap-up
# (Tier 2) and, in Tier 3, nightly by launchd.
# Env: COGENT_HOME (default ~/cogent).
# It auto-archives, it never deletes: every old line is MOVED to brain/archive/.
#   - failed.md and wins.md over 8 KB: the oldest entries move to the archive and leave a
#     one-line summary each.
#   - rules.md over 40 rules: the oldest rules move to the archive, one-line summary each.
#   - journal lines marked [provisional] with (seen: 1), older than 30 days, move to the archive.
#   - claims.md over 60 claims: LOW claims, then the oldest, move to the archive. An unconfirmed
#     claim drops one level (HIGH to MED to LOW) after 90 days; a LOW claim older than 90 days moves.
#   - ideas.md over 30 ideas: the oldest move. gotchas.md over 8 KB: the oldest entries move.
#   - brain/handoff/ files older than 30 days move to the archive.
# It only LISTS, never promotes: journal lessons seen 2 or more times (candidates for claims.md),
# and rules older than 90 days.
# It writes tidy-report.md and commits only brain/ and tidy-report.md.
# The STOP file in COGENT_HOME stops it.
set -u
umask 077
COGENT="${COGENT_HOME:-$HOME/cogent}"
BRAIN="$COGENT/brain"
LOGDIR="$COGENT/logs"
mkdir -p "$LOGDIR"

if [ -e "$COGENT/STOP" ]; then
  echo "$(date -u +%FT%TZ) brain-tidy: STOP file present, not running" >> "$LOGDIR/brain-tidy.log"
  exit 0
fi
[ -d "$BRAIN" ] || { echo "brain-tidy: $BRAIN not found" >&2; exit 1; }

# One run at a time. mkdir is atomic. A lock left by a crash is removed after a day.
LOCK="$COGENT/.brain-tidy.lock"
find "$LOCK" -maxdepth 0 -mmin +1440 -exec rmdir {} \; 2>/dev/null
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "$(date -u +%FT%TZ) brain-tidy: another run holds the lock, exiting" >> "$LOGDIR/brain-tidy.log"
  exit 0
fi
trap 'rmdir "$LOCK"' EXIT

export COGENT BRAIN
python3 - <<'PY'
import os, re, datetime

COGENT = os.environ["COGENT"]
brain = os.environ["BRAIN"]
today = datetime.date.today()
CAP_BYTES = 8192
CAP_RULES = 40
JOURNAL_DAYS = 30
RULE_DAYS = 90
arch_dir = os.path.join(brain, "archive")
moved_log = []          # lines for brain/log.md
report = [f"# Tidy report, {today.isoformat()}", ""]


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, text):
    with open(p, "w", encoding="utf-8") as f:
        f.write(text)


def append_archive(name, text):
    """Add text to a file in brain/archive/. Always before the source file is rewritten."""
    os.makedirs(arch_dir, exist_ok=True)
    with open(os.path.join(arch_dir, name), "a", encoding="utf-8") as f:
        f.write(text if text.endswith("\n") else text + "\n")


def to_date(s):
    try:
        return datetime.date(int(s[0:4]), int(s[5:7]), int(s[8:10]))
    except Exception:
        return None


def note(file, what, why):
    moved_log.append(f"{today.isoformat()} | {file} | {what} | {why}")


SUMMARY = re.compile(r"^- \[archived\] ")

# 1. failed.md and wins.md: entries start with "## ". Newest first, so the oldest are last.
def tidy_entries(name):
    p = os.path.join(brain, name)
    if not os.path.exists(p):
        return f"- {name}: not found, skipped"
    text = read(p)
    if len(text.encode("utf-8")) <= CAP_BYTES:
        return f"- {name}: {len(text.encode('utf-8'))} bytes, under the 8 KB cap"
    lines = text.split("\n")
    head, entries, summaries, cur = [], [], [], None
    for ln in lines:
        if ln.startswith("## "):
            cur = [ln]
            entries.append(cur)
        elif SUMMARY.match(ln):
            summaries.append(ln)
        elif cur is None:
            head.append(ln)
        else:
            cur.append(ln)
    moved = 0
    base = name[:-3]

    def build():
        body = "\n".join(head).rstrip("\n") + "\n\n"
        body += "\n".join("\n".join(e).rstrip("\n") + "\n" for e in entries)
        if summaries:
            body += "\n" + "\n".join(summaries) + "\n"
        return body

    while len(build().encode("utf-8")) > CAP_BYTES and len(entries) > 1:
        e = entries.pop()           # the oldest entry
        title = e[0][3:].strip()
        m = re.match(r"(\d{4}-\d{2}-\d{2})\b", title)
        ym = m.group(1)[:7] if m else today.strftime("%Y-%m")
        append_archive(f"{base}-{ym}.md", "\n".join(e).rstrip("\n") + "\n")
        summaries.append(f"- [archived] {title} (full text: archive/{base}-{ym}.md)")
        note(name, f"archived 1 entry: {title[:60]}", "over 8 KB cap")
        moved += 1
    if moved:
        write(p, build())
    size = len(read(p).encode("utf-8"))
    out = f"- {name}: archived {moved} oldest entr{'y' if moved == 1 else 'ies'} (now {size} bytes)"
    if size > CAP_BYTES:
        out += f". Still over the cap: the newest entry alone is large. Ask your agent to shorten it with you."
    return out

# 2. rules.md: a rule is a line starting "- " outside the <!-- --> comment.
def rule_lines(text):
    out, in_c = [], False
    for i, ln in enumerate(text.split("\n")):
        if "<!--" in ln:
            in_c = True
        if not in_c and ln.startswith("- ") and not SUMMARY.match(ln):
            out.append(i)
        if "-->" in ln:
            in_c = False
    return out


def rule_dates(ln):
    added = None
    m = re.search(r"added (\d{4}-\d{2}-\d{2})", ln)
    if m:
        added = to_date(m.group(1))
    used = None
    m = re.search(r"used (\d{4}-\d{2}-\d{2})", ln)
    if m:
        used = to_date(m.group(1))
    return added, used


rules_msg, old_rules = "- rules.md: not found, skipped", []
rp = os.path.join(brain, "rules.md")
if os.path.exists(rp):
    lines = read(rp).split("\n")
    idx = rule_lines("\n".join(lines))
    n_before = len(idx)
    moved = 0
    if n_before > CAP_RULES:
        # oldest first by date added; a rule with no date counts as new, so it stays
        ranked = sorted(idx, key=lambda i: (rule_dates(lines[i])[0] or today, i))
        drop = set(ranked[: n_before - CAP_RULES])
        gone = []
        for i in sorted(drop):
            ln = lines[i]
            append_archive("rules-archived.md", ln)
            short = re.split(r"\s+Why:", ln[2:])[0][:80]
            lines[i] = f"- [archived] {short} (full text: archive/rules-archived.md)"
            note("rules.md", f"archived rule: {short[:50]}", f"over {CAP_RULES}-rule cap")
            moved += 1
        write(rp, "\n".join(lines))
    rules_msg = f"- rules.md: {n_before - moved} rules (cap {CAP_RULES}); archived {moved}"
    lines = read(rp).split("\n")
    for i in rule_lines("\n".join(lines)):
        added, used = rule_dates(lines[i])
        ref = max([d for d in (added, used) if d], default=None)
        if ref and (today - ref).days > RULE_DAYS:
            old_rules.append((((today - ref).days), lines[i]))

# 2b. claims.md, ideas.md: one line each. Cap by count; claims also decay.
def cap_lines(name, cap, key, order):
    p = os.path.join(brain, name)
    if not os.path.exists(p):
        return None
    lines = read(p).split("\n")
    idx = rule_lines("\n".join(lines))
    moved = 0
    if len(idx) > cap:
        ranked = sorted(idx, key=lambda i: (order(lines[i]), i))
        for i in sorted(ranked[: len(idx) - cap]):
            append_archive(f"{name[:-3]}-archived.md", lines[i])
            short = lines[i][2:].split(" | ")[0][:80]
            lines[i] = f"- [archived] {short} (full text: archive/{name[:-3]}-archived.md)"
            note(name, f"archived: {short[:50]}", f"over {cap}-line cap")
            moved += 1
        write(p, "\n".join(lines))
    return len(idx) - moved, moved


def first_date(ln):
    m = re.search(r"(\d{4}-\d{2}-\d{2})", ln)
    return (to_date(m.group(1)) if m else None) or today


LEVELS = ["LOW", "MED", "HIGH"]
CLAIM_DAYS = 90


def claim_info(ln):
    m = re.search(r"confidence: ?(HIGH|MED|LOW)", ln)
    lvl = m.group(1) if m else "LOW"
    ds = [to_date(x) for x in re.findall(r"(?:since|confirmed|decayed): ?(\d{4}-\d{2}-\d{2})", ln)]
    ref = max([d for d in ds if d], default=None)
    return lvl, ref


claims_msg, decayed, cl_archived = "- claims.md: not found, skipped", [], 0
cp = os.path.join(brain, "claims.md")
if os.path.exists(cp):
    lines = read(cp).split("\n")
    gone = []
    for i in rule_lines("\n".join(lines)):
        if "confidence:" not in lines[i]:
            continue
        lvl, ref = claim_info(lines[i])
        if ref is None or (today - ref).days <= CLAIM_DAYS:
            continue
        short = lines[i][2:].split(" | ")[0][:80]
        if lvl == "LOW":
            append_archive("claims-archived.md", lines[i])
            lines[i] = f"- [archived] {short} (full text: archive/claims-archived.md)"
            note("claims.md", f"archived stale LOW claim: {short[:50]}", f"unconfirmed over {CLAIM_DAYS} days")
            cl_archived += 1
        else:
            new = LEVELS[LEVELS.index(lvl) - 1]
            ln = re.sub(r"confidence: ?(?:HIGH|MED|LOW)(?: \([^)]*\))?", f"confidence: {new}", lines[i], 1)
            ln = re.sub(r" \| decayed: \d{4}-\d{2}-\d{2}", "", ln) + f" | decayed: {today.isoformat()}"
            lines[i] = ln
            decayed.append(f"{short} ({lvl} to {new})")
            note("claims.md", f"decayed {lvl} to {new}: {short[:50]}", f"unconfirmed over {CLAIM_DAYS} days")
    write(cp, "\n".join(lines))
    def claim_rank(ln):
        lvl, ref = claim_info(ln)
        return (LEVELS.index(lvl), ref or today)
    r = cap_lines("claims.md", 60, None, claim_rank)
    claims_msg = (f"- claims.md: {r[0]} claims (cap 60); archived {cl_archived + r[1]} "
                  f"(stale LOW {cl_archived}, over cap {r[1]}); decayed {len(decayed)} one level")
ri = cap_lines("ideas.md", 30, None, first_date)
ideas_msg = (f"- ideas.md: {ri[0]} ideas (cap 30); archived {ri[1]}" if ri else "- ideas.md: not found, skipped")

hmoved = 0
hdir = os.path.join(brain, "handoff")
if os.path.isdir(hdir):
    for fn in sorted(os.listdir(hdir)):
        m = re.match(r"(\d{4}-\d{2}-\d{2})(?:-\d{4})?-.*\.md$", fn)  # YYYY-MM-DD-HHMM-topic.md (the old YYYY-MM-DD-topic.md also works)
        d = to_date(m.group(1)) if m else None
        if d and (today - d).days > 30:
            os.makedirs(arch_dir, exist_ok=True)
            dest = os.path.join(arch_dir, "handoff-" + fn)
            if not os.path.exists(dest):
                os.rename(os.path.join(hdir, fn), dest)
                hmoved += 1
                note(f"handoff/{fn}", "moved to archive", "handoff older than 30 days")

# 3. journal: archive old provisional (seen: 1); list provisional with seen >= 2.
candidates, jmoved = [], 0
jdir = os.path.join(brain, "journal")
if os.path.isdir(jdir):
    for fn in sorted(os.listdir(jdir)):
        if not re.match(r"\d{4}-\d{2}\.md$", fn):
            continue
        p = os.path.join(jdir, fn)
        keep, gone = [], []
        for ln in read(p).split("\n"):
            m = re.match(r"^- (\d{4}-\d{2}-\d{2})\b", ln)
            if m and "[provisional]" in ln:
                s = re.search(r"\(seen: ?(\d+)\)", ln)
                seen = int(s.group(1)) if s else 1
                d = to_date(m.group(1))
                if seen >= 2:
                    candidates.append((fn, seen, ln))
                elif d and (today - d).days > JOURNAL_DAYS:
                    gone.append(ln)
                    continue
            keep.append(ln)
        if gone:
            append_archive(f"journal-{fn}", "\n".join(gone))
            write(p, "\n".join(keep))
            jmoved += len(gone)
            note(f"journal/{fn}", f"archived {len(gone)} stale provisional line(s)",
                 f"older than {JOURNAL_DAYS} days and seen once")

report += ["## Archived to brain/archive/ (nothing is deleted)", "",
           tidy_entries("failed.md"), tidy_entries("wins.md"), tidy_entries("gotchas.md"), rules_msg, claims_msg, ideas_msg,
           f"- handoff: moved {hmoved} file(s) older than 30 days",
           f"- journal: archived {jmoved} provisional line(s) older than {JOURNAL_DAYS} days seen once", ""]
report += ["## Promotion candidates, journal to claims.md (seen 2 or more times). NOT promoted; a claim is added only when she says yes", ""]
report += [f"- {fn}: {ln}" for fn, _, ln in candidates] or ["- none"]
report += ["", f"## Rules older than {RULE_DAYS} days. Keep or drop? Her call", ""]
report += [f"- ({d} days) {ln[2:]}" for d, ln in sorted(old_rules, reverse=True)] or ["- none"]
report += ["", "## Claims that dropped one level (unconfirmed for 90 days). Confirm any that are still true", ""]
report += [f"- {d}" for d in decayed] or ["- none"]
report += [""]
write(os.path.join(COGENT, "tidy-report.md"), "\n".join(report))
# Trip marker for the Tier 3 scout: it starts a model session only when tidy found something to think about.
tripped = bool(candidates or decayed or old_rules or jmoved or cl_archived)
marker = os.path.join(COGENT, ".scout-needed")
if tripped:
    write(marker, today.isoformat() + "\n")

if moved_log:
    lp = os.path.join(brain, "log.md")
    with open(lp, "a", encoding="utf-8") as f:
        f.write("\n".join(moved_log) + "\n")
print("tidy ok: archived=%d candidates=%d old-rules=%d" % (len(moved_log), len(candidates), len(old_rules)))
PY
rc=$?
echo "$(date -u +%FT%TZ) brain-tidy: python exit $rc" >> "$LOGDIR/brain-tidy.log"

# Commit ONLY brain/ and tidy-report.md, so every tidy change can be undone and nothing
# else in ~/cogent (canary list, mailbox, outbox, logs, lanes) ever lands in git.
# The pathspec matters: a bare "git add -A" would stage the whole repository.
if [ "$rc" = 0 ] && git -C "$COGENT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$COGENT" add -- brain/ tidy-report.md >/dev/null 2>&1
  # Refuse to commit anything that looks like a pasted key.
  if git -C "$COGENT" diff --cached -- brain/ tidy-report.md | grep -Eq 'sk-[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{12,}|gh[pousr]_[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE'; then
    git -C "$COGENT" reset -q -- brain/ tidy-report.md >/dev/null 2>&1
    echo "$(date -u +%FT%TZ) brain-tidy: something in brain/ looks like a key, NOT committed. Read the brain files." >> "$LOGDIR/brain-tidy.log"
    [ -x "$COGENT/bin/notify.sh" ] && "$COGENT/bin/notify.sh" "Lane brain-tidy needs you: question waiting" >/dev/null 2>&1
  else
    git -C "$COGENT" commit -q -m "brain-tidy $(date +%F)" -- brain/ tidy-report.md >/dev/null 2>&1 || true
  fi
fi
exit $rc
