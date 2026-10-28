#!/usr/bin/env python3
"""guard.py - PreToolUse hook for Claude Code (python3 standard library only).

Reads the hook JSON from stdin. Exit 0 = allow. Exit 2 = block (reason on stderr).
Logs every decision to $COGENT_HOME/audit/guard.log (default ~/cogent/audit/guard.log).
Fails CLOSED: input it cannot parse is blocked.
If the file $COGENT_HOME/STOP exists, everything this hook sees is blocked.
Changes to the agent's own controls (~/.claude settings, hooks, agents, skills,
CLAUDE.md, any project .claude folder, .mcp.json, brain/rules.md, the audit folder)
make this hook answer "ask", so Evangeline must approve them herself.
Any write to ~/cogent/soul.md also answers "ask" (soul.md changes only on her request).
A Write or Edit to ~/cogent/brain/ whose new text reads like an instruction ("ignore previous",
"you must", "from now on" ...) answers "ask": it belongs in brain/quarantine.md as reported speech.
Reading, searching or editing outside ~/cogent (and outside the folders listed in
$COGENT_HOME/allowed-folders.txt) also answers "ask".

THIS IS A SEATBELT, NOT A VAULT. It reads the text of a command. A command built with
quotes, variables, a script file or an encoded string can hide its meaning. It stops
accidents and the obvious tricks. The real limits are the permission rules, the sandbox
and what is on the machine. See "KNOWN LIMITS" in test-guard.sh.
"""
import datetime
import json
import os
import re
import sys

HOME = os.path.expanduser("~")
COGENT = os.environ.get("COGENT_HOME") or os.path.join(HOME, "cogent")
STOP_FILE = os.path.join(COGENT, "STOP")
LOG_FILE = os.path.join(COGENT, "audit", "guard.log")
ROOTS_FILE = os.path.join(COGENT, "allowed-folders.txt")

SECRET_DIRS = [os.path.join(HOME, d) for d in
               (".ssh", ".aws", ".config/gcloud", "Library/Keychains", ".gnupg", ".kube",
                ".docker", ".config/gh", "Library/Application Support/Google",
                "Library/Safari", "Library/Messages", "Library/Mail", "Library/Cookies")]
# Bait folders inside the workspace: reading a file in them is blocked, but a search over
# ~/cogent itself is routine, so these are NOT checked as search ancestors (covers_secret_dir).
HIDDEN_DIRS = [os.path.join(COGENT, "canary"), os.path.join(COGENT, "decoy")]
SECRET_BASENAMES = {".netrc", ".git-credentials", ".npmrc", ".pypirc", ".pgpass",
                    ".claude.json", ".credentials.json"}
# Files that make the agent's own behaviour: changes always ask.
RE_CTRL_PATH = re.compile(
    r"/\.claude/(?:settings(?:\.local)?\.json|hooks(?:/|$)|agents(?:/|$)|skills(?:/|$)|CLAUDE\.md$)"
    r"|/\.mcp\.json$|/brain/rules\.md$|/CLAUDE\.md$")
RE_CONTROL = re.compile(
    r"\.claude\b(?!/projects)|\.mcp\.json|brain/rules\.md|(?:^|[\s/])CLAUDE\.md\b|cogent/audit")
RE_WRITEISH = re.compile(
    r">|\btee\b|\bsed\s+-[A-Za-z]*i|\b(?:cp|mv|rm|ln|chmod|touch|truncate|install|dd|"
    r"python3?|perl|ruby|node|osascript|sh|bash|zsh|ed|vi|vim|nano|open|rsync|ditto)\b")
RE_SOUL = re.compile(r"(?:^|[\s/\"'=:~])soul\.md" + r"(?=$|[\s\"'`;|&)<>:,*?])")
# Imperative wording in text written to the brain: probably copied from outside.
RE_IMPERATIVE = re.compile(
    r"ignore\s+(?:all|any|every|previous|prior|the\s+above|your)\b|you\s+must\b|from\s+now\s+on\b"
    r"|always\s+do\b|disregard\b", re.I)
RE_QUIET_REDIRECT = re.compile(r"[0-9&]*>>?\s*/dev/null|[0-9]>&[0-9]")
WRITE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
PATH_TOOLS = WRITE_TOOLS | {"Read", "Grep", "Glob"}
ENV_OK = {".env.example", ".env.sample", ".env.template"}
WRAPPERS = {"sudo", "command", "exec", "nohup", "time", "xargs", "builtin", "env"}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh"}
# Folders that never need to be on the allowed list.
ALWAYS_OK = [os.path.join(HOME, ".claude"), "/tmp", "/private/tmp", "/private/var/folders", "/var/folders"]
RE_REDACT = re.compile(
    r"(?i)(bearer\s+|authorization[:=]\s*|(?:token|key|secret|passw(?:or)?d|pwd)[=:\s]+)\S+"
    r"|sk-[A-Za-z0-9_-]{10,}|AKIA[0-9A-Z]{12,}|gh[pousr]_[A-Za-z0-9]{20,}")


def log(decision, tool, detail, reason=""):
    try:
        os.umask(0o077)
        os.makedirs(os.path.dirname(LOG_FILE), mode=0o700, exist_ok=True)
        detail = re.sub(r"\s+", " ", str(detail))[:160]
        detail = RE_REDACT.sub(lambda m: (m.group(1) or "") + "[redacted]", detail)
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        with open(LOG_FILE, "a") as f:
            f.write("%s\t%s\t%s\t%s\t%s\n" % (stamp, decision, tool, detail, reason))
    except Exception:
        pass


def block(tool, detail, reason):
    log("BLOCK", tool, detail, reason)
    sys.stderr.write("Blocked by guard.py: %s. Nothing was run. "
                     "Tell Evangeline what you were trying to do and why; "
                     "do not try another way around this block.\n" % reason)
    sys.exit(2)


def ask(tool, detail, reason):
    log("ASK", tool, detail, reason)
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "guard.py: %s. Evangeline must approve this herself." % reason}}))
    sys.exit(0)


def is_control_path(raw, cwd):
    if not isinstance(raw, str) or not raw:
        return False
    p = os.path.expanduser(raw)
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    audit = os.path.join(COGENT, "audit")
    for c in {os.path.normpath(p), os.path.realpath(p)}:
        if RE_CTRL_PATH.search(c):
            return True
        if c == audit or c.startswith(audit + os.sep):
            return True
    return False


def _norms(raw, cwd):
    p = os.path.expanduser(raw)
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    return {os.path.normpath(p), os.path.realpath(p)}


def is_soul_path(raw, cwd):
    if not isinstance(raw, str) or not raw:
        return False
    want = {os.path.join(COGENT, "soul.md"), os.path.join(os.path.realpath(COGENT), "soul.md")}
    return bool(_norms(raw, cwd) & want)


def brain_target(raw, cwd):
    """The brain file name (relative to brain/) if this path is inside ~/cogent/brain, else None."""
    if not isinstance(raw, str) or not raw:
        return None
    for root in {os.path.join(COGENT, "brain"), os.path.join(os.path.realpath(COGENT), "brain")}:
        for c in _norms(raw, cwd):
            if c.startswith(root + os.sep):
                return c[len(root) + 1:]
    return None


def new_text(ti):
    """All the text a Write/Edit/MultiEdit would put into the file."""
    parts = [ti.get(k) for k in ("content", "new_string", "new_source")]
    for e in ti.get("edits") or []:
        if isinstance(e, dict):
            parts.append(e.get("new_string"))
    return "\n".join(p for p in parts if isinstance(p, str))


def _roots():
    # Temp folders are fine, unless the home folder itself sits inside one (a test setup).
    ok = [r for r in ALWAYS_OK if not HOME.startswith(r.rstrip(os.sep) + os.sep)]
    roots = [COGENT] + ok
    try:
        with open(ROOTS_FILE) as f:
            roots += [os.path.expanduser(l.strip()) for l in f
                      if l.strip() and not l.lstrip().startswith("#")]
    except OSError:
        pass
    return {os.path.normpath(r) for r in roots} | {os.path.realpath(r) for r in roots}


def outside_roots(raw, cwd):
    """True if the path is outside ~/cogent, the always-fine folders and allowed-folders.txt."""
    if not isinstance(raw, str) or not raw:
        return False
    p = os.path.expanduser(raw)
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    for c in {os.path.normpath(p), os.path.realpath(p)}:
        roots = _roots()
        if not any(c == r or c.startswith(r + os.sep) for r in roots):
            return True
    return False


def covers_secret_dir(raw, cwd):
    """True if a search starting at this path would run over a secrets folder."""
    p = os.path.expanduser(raw) if raw else cwd
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    for c in {os.path.normpath(p), os.path.realpath(p)}:
        for d in SECRET_DIRS:
            for dd in {os.path.normpath(d), os.path.realpath(d)}:
                if dd == c or dd.startswith(c.rstrip(os.sep) + os.sep):
                    return True
    return False


def path_reason(raw, cwd):
    """Return a reason string if this file path is a secret location."""
    if not isinstance(raw, str) or not raw:
        return None
    p = os.path.expanduser(raw)
    if not os.path.isabs(p):
        p = os.path.join(cwd, p)
    for c in {os.path.normpath(p), os.path.realpath(p)}:
        base = os.path.basename(c)
        for d in SECRET_DIRS + HIDDEN_DIRS:
            for dd in {os.path.normpath(d), os.path.realpath(d)}:
                if c == dd or c.startswith(dd + os.sep):
                    return "path is inside a secrets folder (%s)" % d.replace(HOME, "~")
        if base == ".env" or (base.startswith(".env.") and base not in ENV_OK):
            return "path is an .env file"
        if base in SECRET_BASENAMES:
            return "path is a credentials file (%s)" % base
        if base.endswith((".pem", ".key", ".p12", ".pfx", ".kdbx")):
            return "path is a key or certificate file"
        if re.match(r"id_(rsa|dsa|ecdsa|ed25519)", base):
            return "path is an SSH private key"
    return None


END = r"(?=$|[\s\"'`;|&)<>:,*?])"
RE_ENV = re.compile(r"(?:^|[\s/\"'=:~*<])(\.env(?:\.[A-Za-z0-9_-]+)?)" + END)
RE_DIRS = re.compile(r"(?:^|[\s/\"'=:~}])\.(?:ssh|aws|gnupg|kube|docker)(?=$|[/\s\"'`;|&)<>*?])"
                     r"|\.config/(?:gcloud|gh)\b|Library/(?:Keychains|Safari|Messages|Mail|Cookies)"
                     r"|Library/Application Support/Google|cogent/(?:canary|decoy)")
RE_CREDFILE = re.compile(r"(?:^|[\s/\"'=:~*<])\.(?:netrc|git-credentials|npmrc|pypirc|pgpass|claude\.json|credentials\.json)" + END)
RE_KEYFILE = re.compile(r"[\w*-]\.(?:pem|key|p12|pfx|kdbx)" + END)
RE_GLOB_SECRET = re.compile(r"(?:^|[\s/])\.(?:en|ss|aw|gn)\w*[*?\[]|[*?\[]env\b")
RE_SECRET_ECHO = re.compile(r"\b(?:echo|printf)\b[^\n;|&]*\$\{?\w*(?:KEY|TOKEN|SECRET|PASS)")
RE_SHELL_PAYLOAD = re.compile(r"\b(?:sh|bash|zsh|dash|ksh)\s+(?:-\w+\s+)*-\w*c\w*\s+(?:'([^']*)'|\"([^\"]*)\")", re.S)
RE_EVAL_PAYLOAD = re.compile(r"\beval\s+(?:'([^']*)'|\"([^\"]*)\"|(.+))", re.S)
RE_IDKEY = re.compile(r"\bid_(?:rsa|dsa|ecdsa|ed25519)")
RE_KEYCHAIN = re.compile(
    r"\bsecurity\s+(?:dump-keychain|export)\b"
    r"|\bsecurity\s+find-(?:generic|internet)-password\b[^|;&\n]*\s-[A-Za-z]*[wg]\b")
RE_PIPE_SHELL = re.compile(
    r"\b(?:curl|wget)\b[^\n]*\|\s*(?:sudo\s+)?(?:\S*/)?(?:ba|z|da|k)?sh\b"
    r"|\b(?:ba|z|da|k)?sh\s+(?:-c\s+)?[\"']?(?:<\(|\$\()\s*(?:curl|wget)\b")


def text_secret_reason(text):
    for m in RE_ENV.finditer(text):
        if m.group(1) not in ENV_OK:
            return "command mentions an .env file"
    if RE_DIRS.search(text):
        return "command mentions a secrets folder (.ssh, .aws, gcloud or Keychains)"
    if RE_CREDFILE.search(text):
        return "command mentions a credentials file"
    if RE_KEYFILE.search(text):
        return "command mentions a key or certificate file"
    if RE_IDKEY.search(text):
        return "command mentions an SSH private key"
    return None


def segments(cmd):
    for seg in re.split(r"&&|\|\||[;&|\n`()]|\$\(", cmd):
        toks = [t.strip("\"'") for t in seg.split()]
        toks = [t for t in toks if t]
        if toks:
            yield toks


def strip_prefix(toks):
    i = 0
    while i < len(toks) and (toks[i] in WRAPPERS or re.match(r"^\w+=", toks[i])
                             or (i > 0 and toks[i - 1] == "env" and toks[i].startswith("-"))):
        i += 1
    return toks[i:]


def payloads(cmd):
    """Text inside quoted bash -c / eval, so it can be checked as a command too."""
    out = []
    for m in RE_SHELL_PAYLOAD.finditer(cmd):
        out.append(m.group(1) or m.group(2) or "")
    for m in RE_EVAL_PAYLOAD.finditer(cmd):
        out.append(m.group(1) or m.group(2) or m.group(3) or "")
    return [p for p in out if p]


def bash_reason(cmd, depth=0):
    r = text_secret_reason(cmd)
    if r:
        return r
    if RE_KEYCHAIN.search(cmd.replace('"', "").replace("'", "")):
        return "command would print or dump Keychain secrets"
    if RE_SECRET_ECHO.search(cmd):
        return "printing a variable that looks like a key, token or password is not allowed"
    if depth < 3:
        for p in payloads(cmd):
            r = bash_reason(p, depth + 1)
            if r:
                return r + " (inside a quoted command)"
    if RE_PIPE_SHELL.search(cmd):
        return "command pipes a download into a shell"
    for toks in segments(cmd):
        # rm -rf
        for i, t in enumerate(toks):
            if os.path.basename(t) == "rm":
                flags = [a for a in toks[i + 1:] if a.startswith("-")]
                short = "".join(a[1:] for a in flags if not a.startswith("--"))
                rec = "r" in short.lower() or "--recursive" in flags
                force = "f" in short or "--force" in flags
                if rec and force:
                    return "rm -rf is never allowed"
        # git push --force
        if "git" in [os.path.basename(t) for t in toks] and "push" in toks:
            args = toks[toks.index("push") + 1:]
            for a in args:
                if a.startswith("--force") or a.startswith("+") or \
                        (re.match(r"^-[A-Za-z]+$", a) and "f" in a):
                    return "force push is never allowed"
                if a in ("--mirror", "--delete", "-d") or a.startswith(":"):
                    return "deleting or mirroring remote branches is never allowed"
        if toks and os.path.basename(toks[0]) == "find" and "-delete" in toks:
            return "find -delete is never allowed"
        core = strip_prefix(toks)
        if not core:
            if toks and os.path.basename(toks[0]) == "env" or \
                    any(os.path.basename(t) == "env" for t in toks[:3]):
                return "printing environment variables is not allowed"
            continue
        head = os.path.basename(core[0])
        rest = core[1:]
        if head == "printenv":
            return "printing environment variables is not allowed"
        if head == "export" and (not rest or "-p" in rest):
            return "printing environment variables is not allowed"
        if head in ("declare", "typeset") and any(a in ("-x", "-p", "-px", "-xp") for a in rest):
            return "printing environment variables is not allowed"
        if head == "set" and not rest:
            return "printing environment variables is not allowed"
    return None


def bash_ask_reason(cmd):
    """Things the guard cannot read or should not decide alone: ask Evangeline."""
    clean = RE_QUIET_REDIRECT.sub(" ", cmd)
    if RE_SOUL.search(clean) and RE_WRITEISH.search(clean):
        return "soul.md changes only on her request"
    if RE_CONTROL.search(clean) and RE_WRITEISH.search(clean):
        return "this command may change the agent's own settings, hooks, rules or logs"
    if RE_GLOB_SECRET.search(cmd) or re.search(r"\*\.(?:pem|key)\b", cmd):
        return "this command uses a wildcard that could match secret files"
    for toks in segments(cmd):
        core = strip_prefix(toks)
        if not core:
            continue
        head = os.path.basename(core[0])
        rest = core[1:]
        if head == "eval":
            return "this runs a program inside a command, which the guard cannot read"
        if head in SHELLS and any(re.match(r"^-\w*c\w*$", a) for a in rest):
            return "this runs a program inside a command, which the guard cannot read"
        if re.match(r"^(?:python[\d.]*|perl|ruby|node)$", head) and \
                any(a in ("-c", "-e", "-r", "-p") for a in rest):
            return "this runs a program inside a command, which the guard cannot read"
        if head == "osascript":
            return "osascript can send mail, read Messages and click through prompts"
    return None


def main():
    if os.path.exists(STOP_FILE):
        block("*", "STOP file present", "the STOP switch is on (%s exists)" % STOP_FILE.replace(HOME, "~"))
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        block("?", "unparseable input", "hook input could not be read, so the action is refused")
    if not isinstance(data, dict) or not isinstance(data.get("tool_name"), str):
        block("?", "unexpected input", "hook input had no tool name, so the action is refused")
    tool = data["tool_name"]
    ti = data.get("tool_input")
    if not isinstance(ti, dict):
        ti = {}
    cwd = data.get("cwd") if isinstance(data.get("cwd"), str) else os.getcwd()

    if tool == "Bash":
        cmd = ti.get("command")
        if not isinstance(cmd, str) or not cmd.strip():
            block(tool, repr(cmd), "Bash call had no readable command, so it is refused")
        reason = bash_reason(cmd)
        if reason:
            block(tool, cmd, reason)
        reason = bash_ask_reason(cmd)
        if reason:
            ask(tool, cmd, reason)
        log("ALLOW", tool, cmd)
        sys.exit(0)

    detail = ""
    for key in ("file_path", "notebook_path", "path"):
        val = ti.get(key)
        if isinstance(val, str) and val:
            detail = detail or val
            reason = path_reason(val, cwd)
            if reason:
                block(tool, val, reason)
            if tool in WRITE_TOOLS and is_soul_path(val, cwd):
                ask(tool, val, "soul.md changes only on her request")
            if tool in WRITE_TOOLS and brain_target(val, cwd) not in (None, "quarantine.md") \
                    and RE_IMPERATIVE.search(new_text(ti)):
                ask(tool, val, "this brain text looks like an instruction; store it in "
                    "brain/quarantine.md as reported speech")
            if tool in WRITE_TOOLS and is_control_path(val, cwd):
                ask(tool, val, "this edits the agent's own settings, hooks, rules or logs")
            if tool in ("Grep", "Glob") and covers_secret_dir(val, cwd):
                ask(tool, val, "this search would run over a folder that holds secrets; search a narrower folder")
            if tool in PATH_TOOLS and outside_roots(val, cwd):
                ask(tool, val, "this path is outside ~/cogent and the folders in allowed-folders.txt")
    if tool in ("WebFetch", "WebSearch"):
        url = ti.get("url") or ti.get("query") or ""
        if isinstance(url, str):
            detail = url
            q = url.split("?", 1)[1] if "?" in url else ""
            if len(q) > 80 or re.search(r"[A-Za-z0-9+/_-]{40,}", url):
                ask(tool, url, "this web address carries a lot of data; it could be sending something out")
    for key in ("pattern", "glob"):
        val = ti.get(key)
        if isinstance(val, str) and tool == "Glob" or key == "glob" and isinstance(val, str):
            detail = detail or val
            reason = text_secret_reason(val)
            if reason:
                block(tool, val, reason.replace("command", "search pattern"))
    if tool in ("Grep", "Glob") and not any(isinstance(ti.get(k), str) and ti.get(k)
                                            for k in ("file_path", "notebook_path", "path")):
        if covers_secret_dir("", cwd):
            ask(tool, cwd, "this search would run over a folder that holds secrets; search a narrower folder")
        if outside_roots(cwd, cwd):
            ask(tool, cwd, "this search starts outside ~/cogent and the folders in allowed-folders.txt")
    log("ALLOW", tool, detail)
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # fail closed
        log("BLOCK", "?", "internal error", repr(exc))
        sys.stderr.write("Blocked by guard.py: internal error, so the action is refused.\n")
        sys.exit(2)
