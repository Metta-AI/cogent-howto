# **For Softmax employees only**

If you do not work at Softmax, skip this file. Nothing in it is needed for Tiers 1 to 3.

## What the company platform is

Softmax builds its own platform for "cogents". A cogent is a persistent, always-on AI coworker. It is not one chat. It is a long-lived entity that uses a language model to think, the way a person uses a single thought. It picks up tasks, talks in the channels people use, reviews work and runs coding agent sessions.

The platform has these ideas:

- **A creation program.** A separate program runs once to create a cogent: it sets up where it lives, loads its starting memory and rules, then ends. The cogent cannot rewrite its own starting rules. Only people or a reviewed deploy can.
- **Skills and triggers.** Everything it does is a skill (a markdown prompt or a small program) started by a trigger (a schedule or an event). Skills are files. Triggers are data.
- **Separate roles.** One part proposes work, another approves it, another does it, another audits it. The doer cannot approve its own work.
- **Scoped memory.** Memory has levels and types. Rules come only from people. Anything the agent writes that sounds like an order is held for human review, not saved as a rule.
- **Credentials held elsewhere.** A separate identity service holds the keys and adds them to requests. The cogent never holds a key, so it cannot leak one.
- **Trust scores.** Each project has a score that rises with good results and falls fast on security problems. Low trust means a human reviews more.
- **Budgets that pause it.** Spend is capped. At the limit the cogent goes dormant and alerts a person.
- **Full traces.** Every session records what it did, so it can be replayed.

## What your local build already copies

| Company idea | Where your build has it |
|---|---|
| Separate roles | Tier 2 `reviewer` subagent reads and cannot edit; `researcher` can only look things up on the web, with no file access; you approve. Tier 3: the agent drafts into the outbox, you approve at your computer, the agent acts |
| Rules come only from people | Evidence-before-rule in the brain: lessons are proposed, only you move one into `rules.md` |
| Scoped memory | `rules.md`, `lessons.md`, per-project notes, project-level CLAUDE.md, size caps |
| Skills and triggers | Skills folder plus scheduled `claude -p` jobs |
| Keys held elsewhere | Keychain (you run every Keychain command yourself), refusal rules on secret files, no keys on the always-on box beyond the agent's own login |
| Budgets that pause it | Subscription limits, spend limits in the console if a key is used, the STOP file |
| Full traces | Daily audit log plus Claude Code transcripts |
| Pain signal reaches a person | Phone alert with a fixed, secret-free shape that says a draft is waiting. Alerts only; approvals happen at your computer |
| Immutable starting rules | Not copied as a lock. The agent must ask you every time before it changes its own settings, rules or hooks, and from Tier 2 the guard forces that question too |
| Trust earned by results | Not copied. You loosen rules by hand, with a reason, never because the agent scored well |

Your build is smaller on purpose. It does not have a separate identity service, so it is weaker on the key point: the agent runs on a machine you own, and the safety comes from permission rules, the sandbox and what is on the machine. Hooks stop accidents and obvious mistakes, not a determined program.

## What you may and may not do

- **Creating a cogent on the company platform needs platform and cloud administrator access you do not have by default.** Ask the team that runs it. Do not try to get around that, and do not have your agent try.
- **Do not connect company accounts to a personal agent** without explicit approval from whoever owns that system. That covers email, chat, code hosting, the task tracker and cloud accounts. This includes read-only access, a personal access token, and a browser session left logged in on the box.
- **Company data stays on company-approved tools.** Do not paste company documents, customer details or code into your personal setup, its brain or its mailbox.
- **Follow the company's acceptable-use rules** for AI tools. If you are unsure whether something counts as company data, ask first.
- Your personal setup is yours. Use it for your own work and notes. Keep it separate from company systems, with its own accounts.

## Who to ask

Ask the team that runs the platform: how to get a cogent, what access is needed, and what the approved path is for using AI tools on company work. If you cannot tell who that is, ask your manager. Do not guess.
